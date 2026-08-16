@EndUserText.label: 'RAP04 Managed vs Unmanaged Demo'
define service ZRAP04_SD {
  expose ZI_RAP02_TASK as TaskManaged;
  expose ZI_RAP03_UMTEST as TestUnmanaged;
}
