package operators

import (
	"context"
	"fmt"

	. "github.com/onsi/ginkgo"
	. "github.com/onsi/gomega"
	appsv1 "k8s.io/api/apps/v1"
	corev1 "k8s.io/api/core/v1"
	rbacv1 "k8s.io/api/rbac/v1"
	apiextensionsv1 "k8s.io/apiextensions-apiserver/pkg/apis/apiextensions/v1"
	apierrors "k8s.io/apimachinery/pkg/api/errors"
	metav1 "k8s.io/apimachinery/pkg/apis/meta/v1"
	"k8s.io/apimachinery/pkg/runtime"
	apiregistrationv1 "k8s.io/kube-aggregator/pkg/apis/apiregistration/v1"

	operatorsv1alpha1 "github.com/operator-framework/api/pkg/operators/v1alpha1"
	"github.com/operator-framework/operator-lifecycle-manager/pkg/controller/operators/decorators"
	"github.com/operator-framework/operator-lifecycle-manager/pkg/lib/ownerutil"
	"github.com/operator-framework/operator-lifecycle-manager/pkg/lib/testobj"
)

var _ = Describe("Adoption Controller", func() {
	var (
		ctx context.Context
	)

	BeforeEach(func() {
		ctx = context.Background()
	})

	Describe("Component label generation", func() {
		var (
			created []runtime.Object
		)

		BeforeEach(func() {
			created = []runtime.Object{}
		})

		JustAfterEach(func() {
			for _, obj := range created {
				Eventually(func() error {
					err := k8sClient.Delete(ctx, obj)
					if apierrors.IsNotFound(err) {
						return nil
					}

					return err
				}).Should(Succeed())
			}
		})

		Context("a subscription", func() {
			var (
				ns  *corev1.Namespace
				sub *operatorsv1alpha1.Subscription
			)

			BeforeEach(func() {
				ns = &corev1.Namespace{}
				ns.SetName(genName("operators-"))

				Eventually(func() error {
					return k8sClient.Create(ctx, ns)
				}, timeout, interval).Should(Succeed())
				created = append(created, ns)
			})

			Context("with a package", func() {
				var (
					componentLabelKey string
					installed         *operatorsv1alpha1.ClusterServiceVersion
				)

				BeforeEach(func() {
					sub = &operatorsv1alpha1.Subscription{
						Spec: &operatorsv1alpha1.SubscriptionSpec{
							Package: "poultry",
						},
						Status: operatorsv1alpha1.SubscriptionStatus{
							InstalledCSV: "turkey",
							LastUpdated:  metav1.Now(),
						},
					}
					sub.SetNamespace(ns.GetName())
					sub.SetName(sub.Spec.Package)

					Eventually(func() error {
						return k8sClient.Create(ctx, sub)
					}, timeout, interval).Should(Succeed())
					created = append(created, sub)

					// Set the Subscription's status separately
					status := sub.DeepCopy().Status
					Eventually(func() error {
						if err := k8sClient.Get(ctx, testobj.NamespacedName(sub), sub); err != nil {
							return err
						}
						sub.Status = status

						return k8sClient.Status().Update(ctx, sub)
					}, timeout, interval).Should(Succeed())

					componentLabelKey = fmt.Sprintf("%s%s.%s", decorators.ComponentLabelKeyPrefix, sub.Spec.Package, sub.GetNamespace())
				})

				Context("that has an existing installed csv", func() {

					BeforeEach(func() {
						installed = &operatorsv1alpha1.ClusterServiceVersion{
							Spec: operatorsv1alpha1.ClusterServiceVersionSpec{
								InstallStrategy: operatorsv1alpha1.NamedInstallStrategy{
									StrategyName: operatorsv1alpha1.InstallStrategyNameDeployment,
									StrategySpec: operatorsv1alpha1.StrategyDetailsDeployment{
										DeploymentSpecs: []operatorsv1alpha1.StrategyDeploymentSpec{},
									},
								},
							},
						}
						installed.SetNamespace(ns.GetName())
						installed.SetName(sub.Status.InstalledCSV)

						Eventually(func() error {
							return k8sClient.Create(ctx, installed)
						}, timeout, interval).Should(Succeed())
						created = append(created, installed)
					})

					Context("that has no resources owned by the installed csv", func() {
						Specify("a component label", func() {
							Eventually(func() (map[string]string, error) {
								latest := &operatorsv1alpha1.ClusterServiceVersion{}
								err := k8sClient.Get(ctx, testobj.NamespacedName(installed), latest)

								return latest.GetLabels(), err
							}, timeout, interval).Should(HaveKey(componentLabelKey))
						})
					})

					Context("that has resources owned by the installed csv", func() {
						var (
							components []testobj.RuntimeMetaObject
						)

						BeforeEach(func() {
							Eventually(func() error {
								return k8sClient.Get(ctx, testobj.NamespacedName(installed), installed)
							}, timeout, interval).Should(Succeed())

							namespace := installed.GetNamespace()
							ownerLabels := map[string]string{
								ownerutil.OwnerKind:         operatorsv1alpha1.ClusterServiceVersionKind,
								ownerutil.OwnerNamespaceKey: namespace,
								ownerutil.OwnerKey:          installed.GetName(),
							}
							components = []testobj.RuntimeMetaObject{
								testobj.WithOwner(
									installed,
									testobj.WithNamespace(
										namespace,
										fixtures.Fill(&appsv1.Deployment{}),
									),
								),
								testobj.WithOwner(
									installed,
									testobj.WithNamespace(
										namespace,
										fixtures.Fill(&corev1.Service{}),
									),
								),
								testobj.WithOwner(
									installed,
									testobj.WithNamespace(
										namespace,
										fixtures.Fill(&corev1.ServiceAccount{}),
									),
								),
								testobj.WithOwner(
									installed,
									testobj.WithNamespace(
										namespace,
										fixtures.Fill(&corev1.Secret{}),
									),
								),
								testobj.WithOwner(
									installed,
									testobj.WithNamespace(
										namespace,
										fixtures.Fill(&corev1.ConfigMap{}),
									),
								),
								testobj.WithOwner(
									installed,
									testobj.WithNamespace(
										namespace,
										fixtures.Fill(&rbacv1.Role{}),
									),
								),
								testobj.WithOwner(
									installed,
									testobj.WithNamespace(
										namespace,
										fixtures.Fill(&rbacv1.RoleBinding{}),
									),
								),
								testobj.WithLabels(
									ownerLabels,
									fixtures.Fill(&rbacv1.ClusterRole{}),
								),
								testobj.WithLabels(
									ownerLabels,
									fixtures.Fill(&rbacv1.ClusterRoleBinding{}),
								),
								testobj.WithLabels(
									ownerLabels,
									fixtures.Fill(&apiextensionsv1.CustomResourceDefinition{}),
								),
								testobj.WithLabels(
									ownerLabels,
									fixtures.Fill(&apiregistrationv1.APIService{}),
								),
							}
							for _, component := range components {
								Eventually(func() error {
									return k8sClient.Create(ctx, component)
								}, timeout, interval).Should(Succeed())
								created = append(created, component)
							}
						})

						Specify("component label", func() {
							for _, component := range components {
								Eventually(func() (map[string]string, error) {
									err := k8sClient.Get(ctx, testobj.NamespacedName(component), component)
									return component.GetLabels(), err
								}, timeout, interval).Should(HaveKey(componentLabelKey))
							}
						})

					})

				})
			})

		})
	})
})
