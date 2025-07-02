package sqi

import (
	"github.com/edenzhang2012/storagequotainterface/sqi/pb"
)

/*
 * This is a default implementation of Unimplemented Quota Service Server.
 * In the future, we will implement some functional methods under this
 * structure that do not require user implementation.
 * Users should implement their own methods based on this structure
 */
type DefaultQuotaServiceServer struct {
	pb.UnimplementedQuotaServiceServer
}
