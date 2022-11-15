# mogdb-stack-helm-charts
mogdb-stack-helm-charts

**Keep helm version >= 3.2**

## add repo

helm repo add mogdb-chart https://enmotech.github.io/mogdb-stack-helm-charts

## update repo

helm repo update mogdb-chart\

## search repo newest chart

helm search repo mogdb-chart

## search repo all chart

helm search repo mogdb-chart -l

## first install

helm install mogdb mogdb-chart/mogdb-operator-chart --namespace mogdb-operator-system --create-namespace

## install

helm install mogdb mogdb-chart/mogdb-operator-chart --namespace mogdb-operator-system

## upgrade

helm upgrade mogdb mogdb-chart/mogdb-operator-chart --version=*****

## rollback

helm rollback mogdb [RELEASE REVISION]