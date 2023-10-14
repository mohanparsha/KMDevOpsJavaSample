	def server = Artifactory.server('MyJFrogServer')
	def rtMaven = Artifactory.newMavenBuild()
	rtMaven.tool = 'M3'
	def buildInfo
	def ARTIFACTORY_LOCAL_SNAPSHOT_REPO = 'KMDevOps-JavaSample/'

	pipeline {
	    agent any
	    environment {
		SPECTRAL_DSN = credentials('spectral-dsn')
		DOCKERHUB_CREDENTIALS = credentials('dockerHubLogin')
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
			    git branch: 'DevSecOps-Demo', url: 'https://github.com/mohanparsha/KMDevOpsJavaSample.git'
		    }
		}
		
		stage('Secrets Scan') {
		    steps {
			    sh "curl -L 'https://get.spectralops.io/latest/x/sh?dsn=$SPECTRAL_DSN' | sh"
			    sh "$HOME/.spectral/spectral scan --all --ok --engines secrets,iac,oss --include-tags base,audit,iac"
		    }
		}

		stage ('Build, Test & Generate SBOM') {
		    steps {
			script {
				rtMaven.tool = 'M3'
				rtMaven.deployer snapshotRepo: ARTIFACTORY_LOCAL_SNAPSHOT_REPO, server: server
				buildInfo = Artifactory.newBuildInfo()
				rtMaven.run pom: 'pom.xml', goals: 'clean install' , buildInfo: buildInfo
			}		
		    }
		}

		stage('Publish Artifact & SBOM') {
		    steps {
			echo "Artifactory Uploaded"
			script {
				rtMaven.deployer.deployArtifacts buildInfo
				server.publishBuildInfo buildInfo
				echo "Artifactory Uploaded"
			}
			withCredentials([string(credentialsId: 'depTrack', variable: 'MyDTAPI-Key')]) {
				dependencyTrackPublisher artifact: 'target/bom.xml', autoCreateProjects: false, dependencyTrackApiKey: '', dependencyTrackFrontendUrl: '', dependencyTrackUrl: '', projectId: 'bf466ade-4ee8-4aa6-93c9-a73a8f062639', projectName: 'KMDevOps-SampleJava', projectVersion: '1.0', synchronous: false
			}
		    }
		}

		stage ('Dependency-Check Vulnerabilities') {
	    	    steps {
			dependencyCheck additionalArguments: '', odcInstallation: 'depcheck'  
   		  	dependencyCheckPublisher pattern: 'dependency-check-report.xml'
	    	    }
		} 

		stage('SAST Scan'){
		    steps{
			   withSonarQubeEnv(installationName: 'MySQ') {
				sh 'mvn clean verify sonar:sonar -Dsonar.projectKey=KMSampleJava'
			    }
		    }
		}
		    
		stage('Build Docker Image'){
			steps{
				sh 'sudo chmod +x mvnw'
				sh 'sudo docker build -t kmdevops-devsecops-demo:latest .'
				sh 'sudo docker images'
				sh 'sudo docker tag kmdevops-devsecops-demo mohanparsha/kmdevops:latest'
				// Push the Image to Docker Hub Public Repo.
				sh 'echo $DOCKERHUB_CREDENTIALS_PSW | docker login -u $DOCKERHUB_CREDENTIALS_USR --password-stdin'
				sh 'sudo docker push mohanparsha/kmdevops:latest'
			}
		}
        
        	stage('Image Scan'){
			steps{
				sh 'sudo docker run --name trivy -v /var/run/docker.sock:/var/run/docker.sock aquasec/trivy image kmdevops-devsecops-demo:latest > trivy-scan-results/trivy-image-scan-$BUILD_NUMBER.txt'
               		}
        	}

	
		stage('QA Release'){
			steps{
				sh 'sudo ssh -i /home/ubuntu/PS-QAEnv-Mumbai-Key.pem ubuntu@$QA_DOCKER_HOST docker run --name KMDevOps-DevSecOps-Demo -p 9090:9090 --cpus="0.50" --memory="256m" -e PORT=9090 -d mohanparsha/kmdevops:latest'
            		}
        	}
	    
		stage('DAST Scan'){
			steps{
				sh 'sudo ssh -i /home/ubuntu/PS-QAEnv-Mumbai-Key.pem ubuntu@$QA_DOCKER_HOST docker run --name OWASP-Zap -t owasp/zap2docker-stable zap-baseline.py -t http://$QA_DOCKER_HOST:9090/ -I'
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
		    
		stage('UAT Release'){
			steps{
				sh 'sudo cp /var/lib/jenkins/workspace/KMDevSecOps-Pipeline-Demo/target/sdktech-demo-0.0.1-SNAPSHOT.jar /home/ubuntu/KM-Demo-WebApp/'
				sh 'sudo chmod +x /home/km/KM-Demo-WebApp/*.jar'
				sh 'sudo java -jar /home/km/KM-Demo-WebApp/sdktech-demo-0.0.1-SNAPSHOT.jar &'
            		}
        	}
		    
		stage ("Env Cleanup") {
		    steps {
			script {
				mail from: "mohan.parsha@gmail.com", to: "mohan.parsha@gmail.com", subject: "APPROVAL REQUIRED FOR Environment Cleanup - $JOB_NAME" , body: """Build $BUILD_NUMBER required an approval. Go to $BUILD_URL for more info."""
				def deploymentDelay = input id: 'Deploy', message: 'Approval for Env. Cleanup?', parameters: [choice(choices: ['0', '1', '2', '3', '4', '5', '6', '7', '8', '9', '10', '11', '12', '13', '14', '15', '16', '17', '18', '19', '20', '21', '22', '23', '24'], description: 'Hours to delay deployment?', name: 'deploymentDelay')]
				sleep time: deploymentDelay.toInteger(), unit: 'HOURS'
			}
			// Cleanup Docker Host
			sleep 15
			sh 'sudo ssh -i /home/km/jenkins-ubuntu-docker km@$QA_DOCKER_HOST docker rm OWASP-Zap'
			sh 'sudo ssh -i /home/km/jenkins-ubuntu-docker km@$QA_DOCKER_HOST docker stop KMDevOps-DevSecOps-Demo'
			sleep 15
			sh 'sudo ssh -i /home/km/jenkins-ubuntu-docker km@$QA_DOCKER_HOST docker rm KMDevOps-DevSecOps-Demo'
			
			// Clean up Jenkins Host
			sh 'sudo docker rm trivy'
			sleep 05
			sh 'sudo docker rmi -f kmdevops-devsecops-demo'
			sh 'sudo docker rmi -f mohanparsha/kmdevops'
			sleep 10
			sh 'sudo docker system prune -f'
			
			// Cleanup Remote Host Deployment
			sleep 05
			sh 'sudo /home/ubuntu/KM-Demo-WebApp/stop-sdktech-app'
		    }
		}
	}
	}
