package restore

// TODO: NEEDS TO BE BUILT OUT, IMPLEMENTED, TESTED, AND RELEASED

import (

	"github.com/spf13/cobra"
)

func NewRestoreCmd() *cobra.Command {
	cmd := &cobra.Command{
		Use:   "restore",
		Short: "Restore your GitHub Enterprise Application",
	}

	// Universal Base Commands
	// EXAMPLE:
	//cmd.AddCommand(repositories.NewRestoreRepositoriesCommand())

	return cmd
}