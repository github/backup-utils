/*
 Licensed under the Apache License, Version 2.0 (the "License");
 you may not use this file except in compliance with the License.
 You may obtain a copy of the License at
     https://www.apache.org/licenses/LICENSE-2.0
 Unless required by applicable law or agreed to in writing, software
 distributed under the License is distributed on an "AS IS" BASIS,
 WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 See the License for the specific language governing permissions and
 limitations under the License.
*/

package log

import (
	"fmt"
	"io"
	"log"
	"os"
)

var (
	debug      = false
	dataLogger = log.New(os.Stderr, "[ghe] ", log.LstdFlags)
)

// Init initializes settings related to logging
func Init(debugFlag bool, out io.Writer) {
	debug = debugFlag
	if debug {
		dataLogger.SetFlags(log.LstdFlags | log.Llongfile)
	}
	dataLogger.SetOutput(out)
}

// DebugEnabled returns whether the debug level is set
func DebugEnabled() bool {
	return debug
}

// Debug is a wrapper for log.Debug
func Debug(v ...interface{}) {
	if debug {
		writeLog(v...)
	}
}

// Debugf is a wrapper for log.Debugf
func Debugf(format string, v ...interface{}) {
	if debug {
		writeLog(fmt.Sprintf(format, v...))
	}
}

// Print is a wrapper for log.Print
func Print(v ...interface{}) {
	writeLog(v...)
}

// Printf is a wrapper for log.Printf
func Printf(format string, v ...interface{}) {
	writeLog(fmt.Sprintf(format, v...))
}

// Fatal is a wrapper for log.Fatal
func Fatal(v ...interface{}) {
	dataLogger.Fatal(v...)
}

// Fatalf is a wrapper for log.Fatalf
func Fatalf(format string, v ...interface{}) {
	dataLogger.Fatalf(format, v...)
}

// Writer returns log output writer object
func Writer() io.Writer {
	return dataLogger.Writer()
}

func writeLog(v ...interface{}) {
	if debug {
		err := dataLogger.Output(3, fmt.Sprint(v...))
		if err != nil {
			log.Print(v...)
			log.Print(err)
		}
	} else {
		dataLogger.Print(v...)
	}
}