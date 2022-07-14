interface IVault {
    function initialize(
        address _owner,
        address _user,
        address _cutFacet,
        address _loupeFacet,
        address _ownershipFacet
    ) external;
}
