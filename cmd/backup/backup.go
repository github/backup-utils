package backup

// TODO: NEEDS TO BE BUILT OUT, IMPLEMENTED, TESTED, AND RELEASED

import (

	"github.com/spf13/cobra"
)

func NewBackUpCmd() *cobra.Command {
	cmd := &cobra.Command{
		Use:   "backup",
		Short: "Backup your GitHub Enterprise Application",
	}

	// Universal Base Commands
	// EXAMPLE:
	//cmd.AddCommand(repositories.NewBackUpRepositoriesCommand())

	return cmd
}