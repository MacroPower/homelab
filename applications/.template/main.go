package main

import (
	"bufio"
	"bytes"
	"fmt"
	"html/template"
	"os"
	"path/filepath"
	"sort"
	"strings"
)

func main() {
	// Prompt the user to enter a value for the name input
	var name string
	fmt.Print("Enter a value for the name input: ")
	fmt.Scanln(&name)

	// Define the input and output directories
	baseInputDir := "applications/.template/base"
	baseOutputDir := filepath.Join("applications/base", name)

	// Template all files in the base input directory
	err := templateDirectory(baseInputDir, baseOutputDir, name)
	if err != nil {
		panic(err)
	}

	// Template all files in each environment directory
	envInputDir := "applications/.template/environments"
	envOutputDir := "applications/environments/"
	err = templateEnvironments(envInputDir, envOutputDir, name)
	if err != nil {
		panic(err)
	}
}

// templateDirectory templates all files in the input directory and writes them to the output directory
func templateDirectory(inputDir string, outputDir string, name string) error {
	return templateFiles(inputDir, outputDir, name)
}

// templateEnvironments templates all files in each environment directory and prompts the user to add the output for each environment
func templateEnvironments(inputDir string, outputDir string, name string) error {
	envOutputDirEntries, err := os.ReadDir(outputDir)
	if err != nil {
		return err
	}

	for _, envOutputDirEntry := range envOutputDirEntries {
		if !envOutputDirEntry.IsDir() {
			continue
		}

		envName := envOutputDirEntry.Name()
		envOutputPath := filepath.Join(outputDir, envName, name)

		if envName == "environments" {
			continue
		}

		// Prompt the user to add the environment output
		reader := bufio.NewReader(os.Stdin)
		fmt.Printf("Do you want to add the output for the %s environment? (y/n): ", envName)
		response, err := reader.ReadString('\n')
		if err != nil {
			return err
		}

		// If the user wants to add the output, template all files in the environment directory
		if strings.ToLower(strings.TrimSpace(response)) == "y" {
			err = templateFiles(inputDir, envOutputPath, name)
			if err != nil {
				return err
			}

			// Add an entry to the imports.libsonnet file in the environment
			importsFilePath := filepath.Join(outputDir, envName, "imports.libsonnet")
			err = addImportToLibsonnet(importsFilePath, name)
			if err != nil {
				return err
			}
		}
	}

	return nil
}

// templateFiles templates all files in the input directory that match the filter function and writes them to the output directory
func templateFiles(inputDir string, outputDir string, name string) error {
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

		// Define the data to be passed to the template
		data := struct {
			Name string
		}{
			Name: name,
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

// addImportToLibsonnet adds an import statement to the imports.libsonnet file
func addImportToLibsonnet(filePath string, name string) error {
	file, err := os.OpenFile(filePath, os.O_CREATE|os.O_APPEND|os.O_RDWR, os.ModePerm)
	if err != nil {
		return err
	}
	defer file.Close()

	// Read the existing imports from the file
	importsScanner := bufio.NewScanner(file)
	importsScanner.Split(bufio.ScanLines)
	var imports []string
	for importsScanner.Scan() {
		txt := strings.TrimSpace(importsScanner.Text())
		if strings.HasPrefix(txt, "import") {
			imports = append(imports, txt)
		}
	}
	if err := importsScanner.Err(); err != nil {
		return err
	}

	// Add the new import to the list and sort it alphabetically
	newImport := fmt.Sprintf(`import '%s/application.libsonnet',`, name)
	imports = append(imports, newImport)
	sort.Strings(imports)

	// Write the updated imports to the file
	file.Truncate(0)
	file.Seek(0, 0)
	file.WriteString("[\n")
	for _, imp := range imports {
		file.WriteString(fmt.Sprintf("  %s\n", imp))
	}
	file.WriteString("]\n")

	return nil
}
