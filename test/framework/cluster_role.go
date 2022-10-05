// Copyright 2017 The prometheus-operator Authors
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//     http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

package framework

import (
	"context"
	rbacv1 "k8s.io/api/rbac/v1"
	metav1 "k8s.io/apimachinery/pkg/apis/meta/v1"
	"k8s.io/apimachinery/pkg/util/yaml"
)

var (
	CRDCreateRule = rbacv1.PolicyRule{
		APIGroups: []string{"apiextensions.k8s.io"},
		Resources: []string{"customresourcedefinitions"},
		Verbs:     []string{"create"},
	}

	CRDMonitoringRule = rbacv1.PolicyRule{
		APIGroups: []string{"apiextensions.k8s.io"},
		Resources: []string{"customresourcedefinitions"},
		ResourceNames: []string{
			"alertmanagers.monitoring.rhobs",
			"podmonitors.monitoring.rhobs",
			"probes.monitoring.rhobs",
			"prometheuses.monitoring.rhobs",
			"prometheusrules.monitoring.rhobs",
			"servicemonitors.monitoring.rhobs",
			"thanosrulers.monitoring.rhobs",
		},
		Verbs: []string{"get", "update"},
	}
)

func (f *Framework) CreateClusterRole(ctx context.Context, relativePath string) (*rbacv1.ClusterRole, error) {
	clusterRole, err := parseClusterRoleYaml(relativePath)
	if err != nil {
		return nil, err
	}

	_, err = f.KubeClient.RbacV1().ClusterRoles().Get(ctx, clusterRole.Name, metav1.GetOptions{})

	if err == nil {
		// ClusterRole already exists -> Update
		clusterRole, err = f.KubeClient.RbacV1().ClusterRoles().Update(ctx, clusterRole, metav1.UpdateOptions{})
		if err != nil {
			return nil, err
		}

	} else {
		// ClusterRole doesn't exists -> Create
		clusterRole, err = f.KubeClient.RbacV1().ClusterRoles().Create(ctx, clusterRole, metav1.CreateOptions{})
		if err != nil {
			return nil, err
		}
	}

	return clusterRole, nil
}

func (f *Framework) DeleteClusterRole(ctx context.Context, relativePath string) error {
	clusterRole, err := parseClusterRoleYaml(relativePath)
	if err != nil {
		return err
	}

	return f.KubeClient.RbacV1().ClusterRoles().Delete(ctx, clusterRole.Name, metav1.DeleteOptions{})
}

func (f *Framework) UpdateClusterRole(ctx context.Context, clusterRole *rbacv1.ClusterRole) error {
	_, err := f.KubeClient.RbacV1().ClusterRoles().Update(ctx, clusterRole, metav1.UpdateOptions{})
	if err != nil {
		return err
	}
	return nil
}

func parseClusterRoleYaml(relativePath string) (*rbacv1.ClusterRole, error) {
	manifest, err := PathToOSFile(relativePath)
	if err != nil {
		return nil, err
	}

	clusterRole := rbacv1.ClusterRole{}
	if err := yaml.NewYAMLOrJSONDecoder(manifest, 100).Decode(&clusterRole); err != nil {
		return nil, err
	}

	return &clusterRole, nil
}
