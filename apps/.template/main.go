package main

import (
	"bufio"
	"bytes"
	"fmt"
	"html/template"
	"os"
	"path/filepath"
	"strings"
)

type templateData struct {
	TenantName string
	AppName    string
}

func main() {
	// Prompt the user to enter a value for the tenant input
	var tenantName string
	fmt.Print("Enter a value for the tenant name input: ")
	fmt.Scanln(&tenantName)

	// Prompt the user to enter a value for the name input
	var appName string
	fmt.Print("Enter a value for the app name input: ")
	fmt.Scanln(&appName)

	// Define the input and output directories
	tenantModInputDir := "apps/.template/templates/_tenant"
	tenantModOutputDir := filepath.Join("apps", tenantName, "_tenant")

	_, err := os.Stat(tenantModOutputDir)
	if err != nil && !os.IsNotExist(err) {
		panic(err)
	}
	if os.IsNotExist(err) {
		fmt.Print("Processing module _tenant\n")
		// Create the output directory if it does not exist
		if err := os.MkdirAll(tenantModOutputDir, 0o700); err != nil {
			panic(err)
		}
		// Template all files in the _tenant input directory
		err := templateDirectory(tenantModInputDir, tenantModOutputDir, templateData{
			TenantName: tenantName,
		})
		if err != nil {
			panic(err)
		}
	}

	// Define the input and output directories
	modInputDir := "apps/.template/templates/app"
	modOutputDir := filepath.Join("apps", tenantName, appName)
	if err := os.MkdirAll(modOutputDir, 0o700); err != nil {
		panic(err)
	}

	// Template all files in each directory
	if err := templateModules(modInputDir, modOutputDir, templateData{
		TenantName: tenantName,
		AppName:    appName,
	}); err != nil {
		panic(err)
	}
}

// templateDirectory templates all files in the input directory and writes them to the output directory
func templateDirectory(inputDir string, outputDir string, data templateData) error {
	fmt.Printf("Processing directory %s\n", inputDir)
	return templateFiles(inputDir, outputDir, data)
}

// templateModules templates all files in each module directory and prompts the user to add the output for each module
func templateModules(inputDir string, outputDir string, data templateData) error {
	modOutputDirEntries, err := os.ReadDir(inputDir)
	if err != nil {
		return fmt.Errorf("failed to read directory %s: %w", inputDir, err)
	}
	fmt.Printf("Found %d modules in %s\n", len(modOutputDirEntries), inputDir)

	for _, modOutputDirEntry := range modOutputDirEntries {
		if !modOutputDirEntry.IsDir() {
			fmt.Printf("Skipping file %s in %s\n", modOutputDirEntry.Name(), outputDir)
			continue
		}
		modName := modOutputDirEntry.Name()
		fmt.Printf("Processing module %s\n", modName)

		response := "y"
		if modName != "base" {
			// Prompt the user to add the module output
			reader := bufio.NewReader(os.Stdin)
			fmt.Printf("Do you want to add the output for the %s module? (y/n): ", modName)
			response, err = reader.ReadString('\n')
			if err != nil {
				return fmt.Errorf("failed to read user input: %w", err)
			}
		}

		// If the user wants to add the output, template all files in the module directory
		if strings.ToLower(strings.TrimSpace(response)) == "y" {
			inModDir := filepath.Join(inputDir, modName)
			outModDir := filepath.Join(outputDir, modName)
			err = templateFiles(inModDir, outModDir, data)
			if err != nil {
				return fmt.Errorf("failed to template files in %s: %w", outModDir, err)
			}
		}
	}

	return nil
}

// templateFiles templates all files in the input directory that match the filter function and writes them to the output directory
func templateFiles(inputDir string, outputDir string, data templateData) error {
	return filepath.Walk(inputDir, func(path string, info os.FileInfo, err error) error {
		if err != nil {
			return err
		}

		// Skip directories
		if info.IsDir() {
			return nil
		}

		// Determine the output path for the current file
		relPath, err := filepath.Rel(inputDir, path)
		if err != nil {
			return err
		}
		outputPath := filepath.Join(outputDir, relPath)

		// Read the input file
		inputBytes, err := os.ReadFile(path)
		if err != nil {
			return err
		}

		// Parse the input file as a Go template
		tmpl, err := template.New(relPath).Parse(string(inputBytes))
		if err != nil {
			return err
		}

		// Render the template with the user input
		var outputBuffer bytes.Buffer
		err = tmpl.Execute(&outputBuffer, data)
		if err != nil {
			return err
		}

		// Write the rendered output to the specified file
		err = os.MkdirAll(filepath.Dir(outputPath), 0755)
		if err != nil {
			return err
		}
		err = os.WriteFile(outputPath, outputBuffer.Bytes(), 0644)
		if err != nil {
			return err
		}

		fmt.Printf("Successfully rendered and saved file to %s\n", outputPath)

		return nil
	})
}
