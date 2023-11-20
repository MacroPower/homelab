package main

import (
	"fmt"
	"os"
	"path/filepath"

	"github.com/google/go-jsonnet"
	"gopkg.in/yaml.v2"
)

// HelmRelease represents the structure for HelmRelease CR
type HelmRelease struct {
	ApiVersion string `yaml:"apiVersion"`
	Kind       string
	Metadata   struct {
		Name      string
		Namespace string
	}
	Spec struct {
		Chart struct {
			Spec struct {
				Chart     string
				Version   string
				SourceRef struct {
					Kind string
					Name string
				} `yaml:"sourceRef"`
			}
		}
		Values interface{}
	}
}

type Application struct {
	APIVersion string `json:"apiVersion"`
	Kind       string `json:"kind"`
	Metadata   struct {
		Name string `json:"name"`
	} `json:"metadata"`
	Spec struct {
		Destination struct {
			Namespace string `json:"namespace"`
		} `json:"destination"`
		Sources []struct {
			Chart string `json:"chart"`
			Helm  struct {
				ReleaseName string   `json:"releaseName"`
				ValueFiles  []string `json:"valueFiles"`
			} `json:"helm"`
			RepoURL        string `json:"repoURL" yaml:"repoURL"`
			TargetRevision string `json:"targetRevision" yaml:"targetRevision"`
		} `json:"sources"`
	} `json:"spec"`
}

func main() {
	baseDir := "applications/base"
	fluxDir := "applications/.flux"
	pwd, _ := os.Getwd()

	// Iterate over directories in baseDir
	err := filepath.Walk(baseDir, func(path string, info os.FileInfo, err error) error {
		if err != nil {
			return err
		}

		if info.IsDir() || filepath.Base(path) != "application.libsonnet" {
			return nil
		}

		// Read Jsonnet file
		jsonnetData, err := os.ReadFile(path)
		if err != nil {
			return err
		}

		os.Chdir(filepath.Dir(path))
		valuesData, err := os.ReadFile("values.yaml")
		if err != nil {
			valuesData = []byte("")
		}

		// Convert Jsonnet to HelmRelease CR
		helmRelease, err := convertJsonnetToHelmRelease(string(jsonnetData), string(valuesData))
		os.Chdir(pwd)
		if err != nil {
			fmt.Printf("Error converting Jsonnet to HelmRelease: %s\n", err)
			return nil
		}

		// Write HelmRelease CR YAML to file
		outputDir := filepath.Join(fluxDir, filepath.Base(filepath.Dir(path)))
		err = os.MkdirAll(outputDir, 0755)
		if err != nil {
			return err
		}

		outputPath := filepath.Join(outputDir, "helmrelease.yaml")
		err = writeHelmReleaseToFile(helmRelease, outputPath)
		if err != nil {
			return err
		}

		fmt.Printf("Generated HelmRelease for %s\n", helmRelease.Metadata.Name)
		return nil
	})

	if err != nil {
		fmt.Printf("Error processing directories: %s\n", err)
	}
}

func convertJsonnetToHelmRelease(jsonnetStr, valuesStr string) (*HelmRelease, error) {
	// Interpret Jsonnet file
	vm := jsonnet.MakeVM()
	vm.Importer(&jsonnet.FileImporter{
		JPaths: []string{"../../vendor"},
	})
	yamlStr, err := vm.EvaluateAnonymousSnippet("application.libsonnet", jsonnetStr)
	if err != nil {
		return nil, err
	}

	var application Application
	err = yaml.Unmarshal([]byte(yamlStr), &application)
	if err != nil {
		return nil, err
	}

	var values map[string]interface{}
	err = yaml.Unmarshal([]byte(valuesStr), &values)
	if err != nil {
		return nil, err
	}

	if len(application.Spec.Sources) == 0 {
		return nil, fmt.Errorf("no sources found for application %s", application.Metadata.Name)
	}

	var helmRelease HelmRelease
	helmRelease.ApiVersion = "helm.toolkit.fluxcd.io/v2beta1"
	helmRelease.Kind = "HelmRelease"
	helmRelease.Metadata.Name = application.Metadata.Name
	helmRelease.Metadata.Namespace = application.Spec.Destination.Namespace
	helmRelease.Spec.Chart.Spec.Chart = application.Spec.Sources[0].Chart
	helmRelease.Spec.Chart.Spec.Version = application.Spec.Sources[0].TargetRevision
	helmRelease.Spec.Chart.Spec.SourceRef.Kind = "HelmRepository"
	helmRelease.Spec.Chart.Spec.SourceRef.Name = application.Spec.Sources[0].RepoURL
	helmRelease.Spec.Values = values

	return &helmRelease, nil
}

func writeHelmReleaseToFile(helmRelease *HelmRelease, outputPath string) error {
	// Convert HelmRelease object to YAML
	yamlData, err := yaml.Marshal(helmRelease)
	if err != nil {
		return err
	}

	// Write YAML to file
	return os.WriteFile(outputPath, yamlData, 0644)
}
