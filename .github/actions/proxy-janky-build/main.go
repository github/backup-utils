package main

import (
	"bytes"
	"encoding/base64"
	"encoding/json"
	"flag"
	"fmt"
	"io"
	"log"
	"net/http"
	"regexp"
	"strings"
	"time"

	"github.com/hashicorp/go-retryablehttp"
)

// Define our Janky Response Structs
type JankyBuildStruct struct {
	Result string
	Url    string
}
type JankyStatusStruct struct {
	Id            string
	Green         bool
	Completed     bool
	StartedAt     string
	CompletedAt   string
	Sha           string
	BuildableName string
}

const (
	pollWaitTime      = 10 * time.Second
	jankyPollTimeout  = 5 * time.Hour
	jankyHttpRetryMax = 5
	jankyUrl          = "https://janky.githubapp.com"
)

func main() {
	// Parse command-line arguments
	job := flag.String("job", "", "Name of the Janky job")
	token := flag.String("token", "", "Name of the Janky token")
	branch := flag.String("branch", "", "Name of the Git branch")
	force := flag.String("force", "false", "Force a build even if one is already passed")
	envVars := flag.String("envVars", "", "Comma separated list of key value pairs to pass to Janky - ex: key1=value1,key2=value2,key3=value3")
	flag.Parse()

	// Validate command-line arguments
	if *job == "" || *token == "" || *branch == "" {
		log.Fatal("job, token and branch flags must be specified")
	}

	// Set up the token + request payload
	authToken := base64.StdEncoding.EncodeToString([]byte(":" + *token))
	type buildRequestObject struct {
		BuildableName string            `json:"buildable_name"`
		BranchName    string            `json:"branch_name"`
		Force         string            `json:"force"`
		EnvVars       map[string]string `json:"env_vars"`
	}

	requestBody := buildRequestObject{
		BuildableName: *job,
		BranchName:    *branch,
		Force:         *force,
	}

	// Parse the envVars flag into a map and add to the request payload
	fmt.Println("Environment Variables:")
	fmt.Println(*envVars)
	if *envVars != "" {
		envVarsMap := make(map[string]string)
		for _, envVar := range strings.Split(*envVars, ",") {
			envVarSplit := strings.Split(envVar, "=")
			envVarsMap[envVarSplit[0]] = envVarSplit[1]
		}
		requestBody.EnvVars = envVarsMap
	}

	payloadBytes, err := json.Marshal(requestBody)
	if err != nil {
		log.Fatal("Failed to marshal the JSON payload!\n" + err.Error())
	}

	// Send build request to Janky
	buildRequest, err := http.NewRequest("POST", jankyUrl+"/api/builds", bytes.NewBuffer(payloadBytes))
	if err != nil {
		log.Fatal("Failed to create build request!\n" + err.Error())
	}
	buildRequest.Header.Set("Content-Type", "application/json")
	buildRequest.Header.Set("Authorization", "Basic "+authToken)
	retryClient := retryablehttp.NewClient() //nolint:all
	retryClient.RetryMax = jankyHttpRetryMax
	retryClient.Logger = nil               // disable debug logging
	client := retryClient.StandardClient() // uses *http.Client
	resp, err := client.Do(buildRequest)
	if err != nil {
		log.Fatal("Failed to send build request!\n" + err.Error())
	}
	defer resp.Body.Close()
	body, err := io.ReadAll(resp.Body)
	if err != nil {
		log.Fatal("Error reading build response!\n" + err.Error())
	}

	// Check if the build was triggered successfully
	if resp.StatusCode == 404 {
		log.Fatal("Failed to trigger build! Either " + *job + " is not the name of a Janky job or " + *branch + " is not a branch for the repository that job belongs to.")
	}
	if resp.StatusCode != 201 {
		log.Fatal("Failed to trigger build! Got exception: " + string(body))
	}

	// Parse the build request response
	var buildResponse JankyBuildStruct
	json.Unmarshal(body, &buildResponse)
	log.Println("Succesfully triggered janky!\n" + buildResponse.Result)

	// Parse the request response for the buildId
	r, err := regexp.Compile("/[0-9]+/")
	if err != nil {
		log.Fatal("Failed to trigger build!\n" + err.Error())
	}
	buildId := strings.Trim(r.FindString(buildResponse.Result), "/")

	// Setup our second HTTP client for reuse in during status polling
	jankyStatusUrl := jankyUrl + "/api/" + buildId + "/status"
	statusRequest, err := http.NewRequest("GET", jankyStatusUrl, nil)
	if err != nil {
		log.Fatal("Failed to create status request!\n" + err.Error())
	}
	statusRequest.Header.Set("Content-Type", "application/json")
	statusRequest.Header.Set("Authorization", "Basic "+authToken)
	retryClient2 := retryablehttp.NewClient()
	retryClient2.RetryMax = jankyHttpRetryMax
	retryClient2.Logger = nil                // disable debug logging
	client2 := retryClient2.StandardClient() // uses *http.Client

	// Wait for a completed status from Janky or break the loop after a certain amount of time
	timeout := time.NewTimer(jankyPollTimeout)
	poll := time.NewTicker(pollWaitTime)

jobLoop:
	for {
		select {
		case <-timeout.C:
			log.Fatal("Failed to poll for build status after " + jankyPollTimeout.String() + "hours")
		case <-poll.C:
			// Send build status request to Janky
			statusResponse, err := client2.Do(statusRequest)
			if err != nil {
				log.Fatal("Failed to send status request!\n" + err.Error())
			}
			defer statusResponse.Body.Close()
			statusBody, err := io.ReadAll(statusResponse.Body)
			if err != nil {
				log.Fatal("Error reading status response!\n" + err.Error())
			}

			// Parse the status response for a green completed build
			var jankyStatusResponse JankyStatusStruct
			json.Unmarshal(statusBody, &jankyStatusResponse)
			//fmt.Println("Janky Status Response:")
			//fmt.Println(string(statusBody))
			if jankyStatusResponse.Completed && jankyStatusResponse.Green {
				log.Println("Janky build Succeeded!")
				break jobLoop
			}
			if jankyStatusResponse.Completed && !jankyStatusResponse.Green {
				log.Fatal("Build failed, see Janky for more info: " + buildResponse.Url)
			}

			// wait for a bit and try again
			log.Println("Build still in progress, will poll for status again in [" + pollWaitTime.String() + "]")
			continue
		}
	}
}
