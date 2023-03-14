// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "@openzeppelin/contracts/proxy/transparent/TransparentUpgradeableProxy.sol";
import "@openzeppelin/contracts/proxy/transparent/ProxyAdmin.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

error Eventually__ALREADY_DEPLOYED();
error Eventually__MISSING_PROXY_ADMIN();
error Eventually__MISSING_EVENT_TEMPLATE();

contract Eventually is Ownable{

    /**
    * The struct for a event
    * We use deployed to keep track of deployments.
    * This is required because both totalSales and yieldedDiscountTokens are 0 when initialized,
    * which would be the same values when the event is not set.
    */
    struct EventBalances {
    bool deployed;
    uint totalSales; // This is in wei
    uint yieldedDiscountTokens;
    }

    // We keep track of deployed events to ensure that callers are all deployed events.
    mapping(address => EventBalances) public events;

    // store proxy admin
    address public proxyAdminAddress;
    ProxyAdmin private proxyAdmin;

    // Event templates (ERC721)
    mapping(address => uint16) private _eventVersions;
    mapping(uint16 => address) private _eventImpls;
    uint16 public eventLatestVersion;

    //Events

    event EventTemplateAdded(address indexed impl, uint16 indexed version);

    event NewEvent(address indexed eventOwner, address indexed newEventAddress);

    constructor(){
        _deployProxyAdmin();
    }

    function initializeProxyAdmin() public onlyOwner {
        if(proxyAdminAddress != address(0))
        {revert Eventually__ALREADY_DEPLOYED();}
        _deployProxyAdmin();
    }

    /**
    * @dev Deploy the ProxyAdmin contract that will manage lock templates upgrades
    * This deploys an instance of ProxyAdmin used by Event transparent proxies.
    */
    function _deployProxyAdmin() private returns (address) {
        proxyAdmin = new ProxyAdmin();
        proxyAdminAddress = address(proxyAdmin);
        return address(proxyAdmin);
    }

    /**
    * @dev Helper to get the version number of a template from his address
    */
    function eventVersions(address _impl) external view returns (uint16) {
        return _eventVersions[_impl];
    }

    /**
    * @dev Helper to get the address of a template based on its version number
    */
    function eventImpls(uint16 _version) external view returns (address) {
        return _eventImpls[_version];
    }

    /**
    * @dev Registers a new Event template immplementation
    * The template is identified by a version number
    * Once registered, the template can be used to upgrade an existing Lock
    */
    function addEventTemplate(address impl,uint16 version) public onlyOwner {
        _eventVersions[impl] = version;
        _eventImpls[version] = impl;
        if (eventLatestVersion < version)
        {
            eventLatestVersion = version;
        }
        
        emit EventTemplateAdded(impl, version);
    }

    /**
    * Create an upgradeable event using a specific Event version
    * @param data bytes containing the call to initialize the event template
    * @param _eventVersion the version of the event to use
    */
    function createUpgradeableEventAtVersion(bytes memory data, uint16 _eventVersion) public returns (address) {
        if(proxyAdminAddress == address(0)){
            revert Eventually__MISSING_PROXY_ADMIN();
        }

        // get Event version
        address eventImpl = _eventImpls[_eventVersion];
        if(eventImpl == address(0)){
            revert Eventually__MISSING_EVENT_TEMPLATE();
        }

        // deploy a proxy pointing to impl
        TransparentUpgradeableProxy proxy = new TransparentUpgradeableProxy(eventImpl, proxyAdminAddress, data);
        address payable newEvent = payable(address(proxy));

        // assign the new Event
        events[newEvent] = EventBalances({
            deployed: true,
            totalSales: 0,
            yieldedDiscountTokens: 0
        });

        // trigger event
        emit NewEvent(msg.sender, newEvent);
        return newEvent;
    }
}