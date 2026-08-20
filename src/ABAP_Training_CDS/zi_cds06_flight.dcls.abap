@EndUserText.label: 'CDS06: Access rule - only AA carrier visible'
@MappingRole: true
define role ZI_CDS06_FLIGHT {
  grant select on ZI_CDS06_FLIGHT
    where carrid = 'AA';
}
