// SPDX-FileCopyrightText: 2020-present Open Networking Foundation <info@opennetworking.org>
//
// SPDX-License-Identifier: Apache-2.0

package utils

import (
	prototypes "github.com/gogo/protobuf/types"
	hwapi "github.com/onosproject/onos-api/go/onos/kpimon"
	"github.com/onosproject/onos-lib-go/pkg/logging"
	measurementStore "github.com/tuongthehaianh123/HW/HW/pkg/store/measurements"
)

var log = logging.GetLogger("utils", "parser")

// ParseEntry parses measurement store entry
func ParseEntry(entry *measurementStore.Entry) *hwapi.MeasurementItems {
	var err error

	measEntryItems := entry.Value.([]measurementStore.MeasurementItem)
	measItem := &hwapi.MeasurementItem{}
	measItems := &hwapi.MeasurementItems{}
	for _, entryItem := range measEntryItems {
		measItem.MeasurementRecords = make([]*hwapi.MeasurementRecord, 0)
		for _, record := range entryItem.MeasurementRecords {
			var value *prototypes.Any
			switch val := record.MeasurementValue.(type) {
			case int64:
				intValue := &hwapi.IntegerValue{Value: val}
				value, err = prototypes.MarshalAny(intValue)
				if err != nil {
					log.Warn(err)
					continue
				}

			case float64:
				realValue := &hwapi.RealValue{
					Value: val,
				}
				value, err = prototypes.MarshalAny(realValue)
				if err != nil {
					log.Warn(err)
					continue
				}
			case int32:
				noValue := &hwapi.NoValue{
					Value: val,
				}
				value, err = prototypes.MarshalAny(noValue)
				if err != nil {
					log.Warn(err)
					continue
				}

			}

			measRecord := &hwapi.MeasurementRecord{
				MeasurementName:  record.MeasurementName,
				Timestamp:        record.Timestamp,
				MeasurementValue: value,
			}
			measItem.MeasurementRecords = append(measItem.MeasurementRecords, measRecord)
		}
		measItems.MeasurementItems = append(measItems.MeasurementItems, measItem)
	}
	return measItems
}
