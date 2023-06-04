	def server = Artifactory.server('MyJFrogServer')
	def rtMaven = Artifactory.newMavenBuild()
	rtMaven.tool = 'M3'
	def buildInfo
	def ARTIFACTORY_LOCAL_SNAPSHOT_REPO = 'KMDevOps-JavaSample/'

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
			    git branch: 'withJFrog-Secrets-Sonar-Cyclone-depTrack', url: 'https://github.com/mohanparsha/KMDevOpsJavaSample.git'
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

		stage ('Build, Test & Generate SBOM') {
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

		stage('SAST Scan'){
		    steps{
			   withSonarQubeEnv(installationName: 'MySQ') {
				sh 'mvn clean verify sonar:sonar -Dsonar.projectKey=KMSampleJava'
			    }
		    }
		}
		    
		stage('Publish SBOM') {
			steps {
				withCredentials([string(credentialsId: 'depTrack', variable: 'MyDTAPI-Key')]) {
					//dependencyTrackPublisher artifact: 'target/bom.xml', projectName: 'KMDevOps-SampleJava', projectVersion: '1.0', synchronous: true, dependencyTrackApiKey: MyDTAPI-Key, projectProperties: [tags: ['kmsdevops-samplejava']]
					dependencyTrackPublisher artifact: 'target/bom.xml', autoCreateProjects: false, dependencyTrackApiKey: '', dependencyTrackFrontendUrl: '', dependencyTrackUrl: '', projectId: 'fb9a1312-378d-4bcf-b91c-eb8d57a6e00e', projectName: 'KMDevOps-SampleJava', projectVersion: '1.0', synchronous: false
				}
            		}
        	}

	
		stage ("QA Approval") {
		    steps {
			script {
				mail from: "mohan.parsha@gmail.com", to: "mohan.parsha@gmail.com", subject: "APPROVAL REQUIRED FOR QA Release - $JOB_NAME" , body: """Build $BUILD_NUMBER required an approval. Go to $BUILD_URL for more info."""
				def deploymentDelay = input id: 'Deploy', message: 'Release to QA?', parameters: [choice(choices: ['0', '1', '2', '3', '4', '5', '6', '7', '8', '9', '10', '11', '12', '13', '14', '15', '16', '17', '18', '19', '20', '21', '22', '23', '24'], description: 'Hours to delay deployment?', name: 'deploymentDelay')]
				sleep time: deploymentDelay.toInteger(), unit: 'HOURS'
			}
		    }
		}

		stage('QA Release'){
			steps{
				sshagent(['UHost']) {
					sh 'ssh -o StrictHostKeyChecking=no km@192.168.29.96  scp km@192.168.29.96:/home/km/KMDevOpsSampleWebApp/ target/bom.xml'
					//sh 'ssh -o StrictHostKeyChecking=no km@192.168.29.96 scp target/sdktech-demo-0.0.1-SNAPSHOT.jar km@192.168.29.96:/home/km/KMDevOpsSampleWebApp'
				}
		    	}
		}

		stage ("UAT Approval") {
		    steps {
			script {
				mail from: "mohan.parsha@gmail.com", to: "mohan.parsha@gmail.com", subject: "APPROVAL REQUIRED FOR UAT Release - $JOB_NAME" , body: """Build $BUILD_NUMBER required an approval. Go to $BUILD_URL for more info."""
				def deploymentDelay = input id: 'Deploy', message: 'Release to UAT?', parameters: [choice(choices: ['0', '1', '2', '3', '4', '5', '6', '7', '8', '9', '10', '11', '12', '13', '14', '15', '16', '17', '18', '19', '20', '21', '22', '23', '24'], description: 'Hours to delay deployment?', name: 'deploymentDelay')]
				sleep time: deploymentDelay.toInteger(), unit: 'HOURS'
			}
		    }
		}

// 	    post {
// 		always {
// 			mail bcc: '', body: "<br>Project: ${env.JOB_NAME} <br>Build Number: ${env.BUILD_NUMBER} <br>URL: ${env.BUILD_URL}", cc: '', charset: 'UTF-8', from: '', mimeType: 'text/html', replyTo: '', subject: "Success: Project name -> ${env.JOB_NAME}", to: "mohan.parsha@gmail.com";
// 		}
// 		failure {
// 			sh 'echo "This will run only if failed"'
// 			//mail bcc: '', body: "<br>Project: ${env.JOB_NAME} <br>Build Number: ${env.BUILD_NUMBER} <br>URL: ${env.BUILD_URL}", cc: '', charset: 'UTF-8', from: '', mimeType: 'text/html', replyTo: '', subject: "ERROR: Project name -> ${env.JOB_NAME}", to: "mohan.parsha@gmail.com";
// 		}
// 	  }
	}
	}
