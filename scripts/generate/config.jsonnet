local v = importstr '../../VERSION';

{
  namespace: 'default',
  version: std.strReplace(v, '\n', ''),
  image: 'quay.io/sthaha/obo-prometheus-operator:v' + self.version,
  configReloaderImage: 'quay.io/sthaha/obo-prometheus-config-reloader:v' + self.version,
}
