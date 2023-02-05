package hostcheck

// TODO: NEEDS TO BE BUILT OUT, IMPLEMENTED, TESTED, AND RELEASED
// MAKE IMPLEMENTATION IN pkg/restore/restore.go
// IMPORT ./pkg/restore

import (

	"github.com/spf13/cobra"
)

func NewHostCheckCmd() *cobra.Command {
	cmd := &cobra.Command{
		Use:   "hostcheck",
		Short: "Check the host configuration of your GitHub Enterprise Application",
	}

	// Universal Base Commands
	// EXAMPLE:
	//cmd.AddCommand(config.NewHostCheckConfigCommand())

	return cmd
}