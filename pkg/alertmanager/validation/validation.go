// Copyright 2022 The prometheus-operator Authors
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

package validation

import (
	"encoding/json"
	"fmt"

	"github.com/pkg/errors"
	"github.com/prometheus/alertmanager/config"
	monitoringv1 "github.com/rhobs/obo-prometheus-operator/pkg/apis/monitoring/v1"
	"github.com/rhobs/obo-prometheus-operator/pkg/operator"
)

// ValidateAlertmanager runs extra validation on the AlertManager fields which
// can't be done at the CRD schema validation level.
func ValidateAlertmanager(am *monitoringv1.Alertmanager) error {
	// TODO(slashpai): Remove this validation after v0.60 since this is handled at CRD level
	if am.Spec.Retention != "" {
		if err := operator.ValidateDurationField(string(am.Spec.Retention)); err != nil {
			return errors.Wrap(err, "invalid retention value specified")
		}
	}

	// TODO(slashpai): Remove this validation after v0.60 since this is handled at CRD level
	if am.Spec.ClusterGossipInterval != "" {
		if err := operator.ValidateDurationField(string(am.Spec.ClusterGossipInterval)); err != nil {
			return errors.Wrap(err, "invalid clusterGossipInterval value specified")
		}
	}

	// TODO(slashpai): Remove this validation after v0.60 since this is handled at CRD level
	if am.Spec.ClusterPushpullInterval != "" {
		if err := operator.ValidateDurationField(string(am.Spec.ClusterPushpullInterval)); err != nil {
			return errors.Wrap(err, "invalid clusterPushpullInterval value specified")
		}
	}

	// TODO(slashpai): Remove this validation after v0.60 since this is handled at CRD level
	if am.Spec.ClusterPeerTimeout != "" {
		if err := operator.ValidateDurationField(string(am.Spec.ClusterPeerTimeout)); err != nil {
			return errors.Wrap(err, "invalid clusterPeerTimeout value specified")
		}
	}

	return nil
}

// ValidateAlertmanagerConfig checks that the given resource complies with the

// ValidateURL against the config.URL
// This could potentially become a regex and be validated via OpenAPI
// but right now, since we know we need to unmarshal into an upstream type
// after conversion, we validate we don't error when doing so
func ValidateURL(url string) (*config.URL, error) {
	var u config.URL
	err := json.Unmarshal([]byte(fmt.Sprintf(`"%s"`, url)), &u)
	if err != nil {
		return nil, fmt.Errorf("validate url from string failed for %s: %w", url, err)
	}
	return &u, nil
}
