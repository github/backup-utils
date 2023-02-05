package main

import (
	"fmt"
	"os"

	"github.com/github/backup-utils/cmd"
)

func main() {
	if err := cmd.NewGHECommand().Execute(); err != nil {
		fmt.Fprintln(os.Stderr, err)
		os.Exit(1)
	}
	os.Exit(0)
}