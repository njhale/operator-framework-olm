module github.com/operator-framework/operator-lifecycle-manager

go 1.13

require (
	github.com/blang/semver v3.5.1+incompatible
	github.com/bshuster-repo/logrus-logstash-hook v1.0.0 // indirect
	github.com/coreos/go-semver v0.3.0
	github.com/davecgh/go-spew v1.1.1
	github.com/fsnotify/fsnotify v1.4.9
	github.com/ghodss/yaml v1.0.0
	github.com/go-bindata/go-bindata/v3 v3.1.3
	github.com/go-logr/logr v0.2.1
	github.com/go-logr/zapr v0.2.0 // indirect
	github.com/go-openapi/spec v0.19.4
	github.com/golang/mock v1.3.1
	github.com/google/go-cmp v0.5.0
	github.com/irifrance/gini v1.0.1
	github.com/itchyny/gojq v0.11.0
	github.com/maxbrunsfeld/counterfeiter/v6 v6.2.2
	github.com/mikefarah/yq/v3 v3.0.0-20201020025845-ccb718cd0f59
	github.com/mitchellh/hashstructure v1.0.0
	github.com/mitchellh/mapstructure v1.1.2
	github.com/onsi/ginkgo v1.12.0
	github.com/onsi/gomega v1.9.0
	github.com/openshift/api v0.0.0-20200331152225-585af27e34fd
	github.com/openshift/client-go v0.0.0-20200326155132-2a6cd50aedd0
	github.com/operator-framework/api v0.3.23
	github.com/operator-framework/operator-registry v1.13.6
	github.com/otiai10/copy v1.2.0
	github.com/pkg/errors v0.9.1
	github.com/prometheus/client_golang v1.7.1
	github.com/prometheus/client_model v0.2.0
	github.com/prometheus/common v0.10.0
	github.com/sirupsen/logrus v1.7.0
	github.com/spf13/cobra v1.0.0
	github.com/spf13/pflag v1.0.5
	github.com/stretchr/testify v1.6.1
	golang.org/x/time v0.0.0-20191024005414-555d28b269f0
	google.golang.org/grpc v1.30.0
	gopkg.in/yaml.v2 v2.2.8
	helm.sh/helm/v3 v3.4.0
	k8s.io/api v0.19.3
	k8s.io/apiextensions-apiserver v0.19.3
	k8s.io/apimachinery v0.19.3
	k8s.io/apiserver v0.19.3
	k8s.io/client-go v0.19.3
	k8s.io/code-generator v0.19.3
	k8s.io/component-base v0.19.3
	k8s.io/klog v1.0.0
	k8s.io/kube-aggregator v0.19.3
	k8s.io/kube-openapi v0.0.0-20200805222855-6aeccd4b50c6
	rsc.io/letsencrypt v0.0.3 // indirect
	sigs.k8s.io/controller-runtime v0.6.0
	sigs.k8s.io/controller-tools v0.3.0
	sigs.k8s.io/kind v0.7.0
)

replace (
	github.com/Azure/go-autorest => github.com/Azure/go-autorest v13.3.2+incompatible
	github.com/docker/docker => github.com/moby/moby v0.7.3-0.20190826074503-38ab9da00309 // Required by Helm

	// controller runtime
	github.com/openshift/api => github.com/openshift/api v0.0.0-20200331152225-585af27e34fd // release-4.5
	github.com/openshift/client-go => github.com/openshift/client-go v0.0.0-20200326155132-2a6cd50aedd0 // release-4.5

	// pinned because latest etcd does not yet work with the latest grpc version (1.30.0)
	go.etcd.io/etcd => go.etcd.io/etcd v0.5.0-alpha.5.0.20200520232829-54ba9589114f
	google.golang.org/grpc => google.golang.org/grpc v1.27.0
	google.golang.org/grpc/examples => google.golang.org/grpc/examples v0.0.0-20200709232328-d8193ee9cc3e

	// pinned because no tag supports 1.18 yet
	// pinned because no tag supports 1.18 yet
	sigs.k8s.io/controller-runtime => sigs.k8s.io/controller-runtime v0.5.1-0.20200414221803-bac7e8aaf90a
	sigs.k8s.io/structured-merge-diff => sigs.k8s.io/structured-merge-diff v1.0.1-0.20191108220359-b1b620dd3f06
)
