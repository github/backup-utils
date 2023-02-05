package cmd

import (
	"os"

	"github.com/github/backup-utils/pkg/log"
	"github.com/spf13/cobra"

	"github.com/github/backup-utils/cmd/backup"
	"github.com/github/backup-utils/cmd/hostcheck"
	"github.com/github/backup-utils/cmd/restore"
)

func NewGHECommand() *cobra.Command {
	var debug bool
	cmd := &cobra.Command{
		Use:	"ghe",
		Short:  "GitHub Enterprise CLI Tool To BackUp and Restore GHES",
		PersistentPreRun: func(cmd *cobra.Command, args []string) {
			log.Init(debug, os.Stderr)
		},			
	}
	
	// Persistent Global Flags
	cmd.PersistentFlags().BoolVar(&debug, "debug", false, "specify debug level")
	
	// Persistent Global Commands
	cmd.AddCommand(backup.NewBackUpCmd())
	cmd.AddCommand(hostcheck.NewHostCheckCmd())
	cmd.AddCommand(restore.NewRestoreCmd())
	return cmd
}
