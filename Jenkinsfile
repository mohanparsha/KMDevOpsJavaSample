	def server = Artifactory.server('MyJFrogServer')
	def rtMaven = Artifactory.newMavenBuild()
	rtMaven.tool = 'M3'
	def buildInfo
	def ARTIFACTORY_LOCAL_SNAPSHOT_REPO = 'KMJavaSample-local-repo/'
	def ARTIFACTORY_VIRTUAL_SNAPSHOT_REPO = 'KMJavaSample-virtual-repo/'

	pipeline {
	    agent any
	    environment {
		SPECTRAL_DSN = credentials('spectral-dsn')
	    }
	    tools { 
		maven 'M3'
	    }
	    options { 
	    timestamps ()
	    buildDiscarder logRotator(artifactDaysToKeepStr: '', artifactNumToKeepStr: '', daysToKeepStr: '10', numToKeepStr: '5')
	    }

	    stages {
		stage('Code Checkout') {
		    steps {
			    git branch: 'withJFrog-Integration', url: 'https://github.com/mohanparsha/KMDevOpsJavaSample.git'
			//git branch: 'sonar', url: 'https://github.com/mohanparsha/KMDevOpsJavaSample.git'
		    }
		}
		stage('Tool Setup') {
			// preflight is a tool that makes sure your CI processes run securely and are safe to use. 
			// To learn more and install preflight, see here: https://github.com/SpectralOps/preflight
		    steps {
			sh "curl -L 'https://get.spectralops.io/latest/x/sh?dsn=$SPECTRAL_DSN' | sh"
		    }
		}
		stage('Secrets Scan') {
		    steps {
			sh "$HOME/.spectral/spectral scan --ok --engines secrets,iac,oss --include-tags base,audit,iac"
		    }
		}    

		stage ('Build & Test') {
		    steps {
			script {
				rtMaven.tool = 'M3'
				rtMaven.deployer snapshotRepo: ARTIFACTORY_LOCAL_SNAPSHOT_REPO, server: server
				buildInfo = Artifactory.newBuildInfo()
				rtMaven.run pom: 'pom.xml', goals: 'clean install' , buildInfo: buildInfo
				//rtMaven.run pom: 'pom.xml', goals: 'clean install', buildInfo: buildInfo
				//rtMaven.run pom: '/var/lib/jenkins/workspace/SDKTech-DevSecOps-Demo/pom.xml', goals: 'clean install'
			}		
		    }
		    post {
		       success {
			    junit 'target/surefire-reports/**/*.xml'
			}   
		    }
		}

		stage('Publish Artifact') {
		    steps {
			    echo "Artifactory Uploaded"
			script {
				rtMaven.deployer.deployArtifacts buildInfo
				server.publishBuildInfo buildInfo
				echo "Artifactory Uploaded"
			}
		    }
		}
	}
}
