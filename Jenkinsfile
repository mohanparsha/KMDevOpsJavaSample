	def server = Artifactory.server('MyJFrogServer')
	def rtMaven = Artifactory.newMavenBuild()
	rtMaven.tool = 'M3'
	def buildInfo
	def ARTIFACTORY_LOCAL_SNAPSHOT_REPO = 'KMDevOps-JavaSample/'
	qa_docker_host = "ssh://bitnami@192.168.29.96"

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
		stage('Tool Setup') {
			// preflight is a tool that makes sure your CI processes run securely and are safe to use. 
			// To learn more and install preflight, see here: https://github.com/SpectralOps/preflight
		    steps {
			sh "curl -L 'https://get.spectralops.io/latest/x/sh?dsn=$SPECTRAL_DSN' | sh"
		    }
		}
		stage('Secrets Scan') {
		    steps {
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

// 		stage('SAST Scan'){
// 		    steps{
// 			   withSonarQubeEnv(installationName: 'MySQ') {
// 				sh 'mvn clean verify sonar:sonar -Dsonar.projectKey=KMSampleJava'
// 			    }
// 		    }
// 		}
		    
// 		stage('Publish SBOM') {
// 			steps {
// 				withCredentials([string(credentialsId: 'depTrack', variable: 'MyDTAPI-Key')]) {
// 					//dependencyTrackPublisher artifact: 'target/bom.xml', autoCreateProjects: false, dependencyTrackApiKey: '', dependencyTrackFrontendUrl: '', dependencyTrackUrl: '', projectId: 'fb9a1312-378d-4bcf-b91c-eb8d57a6e00e', projectName: 'KMDevOps-SampleJava', projectVersion: '1.0', synchronous: false
// 				}
//             		}
//         	}
		    
		stage('Building Docker Image'){
			steps{
				sh 'sudo chmod +x mvnw'
				sh 'sudo docker build -t kmdevops-devsecops-demo:latest .'
				//sh 'sudo docker build -t kmdevops-devsecops-demo:$BUILD_NUMBER .'
				sh 'sudo docker images'
				sh 'docker tag kmdevops-devsecops-demo mohanparsha/kmdevops:latest'
				//sh ' sudo docker push kmdevops-devsecops-demo:$BUILD_NUMBER'
				//sh 'sudo docker push mohanparsha/kmdevops:kmdevops-devsecops-demo:$BUILD_NUMBER'
				
				sh 'echo $DOCKERHUB_CREDENTIALS_PSW | docker login -u $DOCKERHUB_CREDENTIALS_USR --password-stdin'
				sh ' sudo docker push mohanparsha/kmdevops:latest'
				
// 				withDockerRegistry(credentialsId: 'dockerHubLogin', url: '') {
// 					sh ' sudo docker push mohanparsha/kmdevops-devsecops-demo:$BUILD_NUMBER'
// 				}
				
// 				withEnv(["DOCKER_HOST=${qa_docker_host}"]) {
// 					sshagent( credentials: ['UHost']) {
// 						//sh "ssh km@192.168.29.96  sudo docker images"
// 						script {
// 							sh """ssh km@192.168.29.96 << EOF
// 							sudo docker images
// 							sudo docker ps
// 							sh 'sudo docker run --name KMDevOps-Demo -p 9090:9090 --cpus="0.50" --memory="256m" -e PORT=9090 -d kmdevops-demo:$BUILD_NUMBER'
// 							exit
// 							EOF"""
// 						}
//             				}
//         			}
				
				
// 				sshagent(['UHost']) {
// 					//sh 'ssh km@192.168.29.96  uname -a'
// 					//sh 'scp target/bom.xml km@192.168.29.96:/home/km/KMDevOpsSampleWebApp/'
// 					//sh 'sudo chmod +x /bitnami/jenkins/home/workspace/DevSecOps-Demo/mvnw'
//                 			sh 'sudo docker build -t kmdevops-devsecops-demo:$BUILD_NUMBER .'
//                 			sh ' sudo docker images'
// 				}
// 				sh 'sudo chmod +x /bitnami/jenkins/home/workspace/DevSecOps-Demo/mvnw'
//                 		sh 'sudo docker build -t kmdevops-devsecops-demo:$BUILD_NUMBER .'
//                 		sh 'sudo docker images'
			}
		}
        
        	stage('Vulnerability Scanning'){
			steps{
				sh 'sudo docker run -v /var/run/docker.sock:/var/run/docker.sock aquasec/trivy image kmdevops-devsecops-demo:latest > $WORKSPACE/trivy-image-scan-$BUILD_NUMBER.txt'
// 				sshagent(['UHost']) {
// 					//sh 'ssh km@192.168.29.96  uname -a'
// 					//sh 'scp target/bom.xml km@192.168.29.96:/home/km/KMDevOpsSampleWebApp/'
// 					//sh 'sudo trivy image kmdevops-devsecops-demo:latest > $WORKSPACE/trivy-image-scan-$BUILD_NUMBER.txt'
// 					sh 'sudo docker run -v /var/run/docker.sock:/var/run/docker.sock aquasec/trivy image kmdevops-devsecops-demo:latest'
// 				}
				//sh 'sudo trivy image kmdevops-devsecops-demo:$BUILD_NUMBER > $WORKSPACE/trivy-image-scan-$BUILD_NUMBER.txt'
               		}
        	}

	
		stage('QA Release'){
			steps{
				//sh 'docker --hostname ssh://km@192.168.29.96 run -p 9090:9090 --cpus="0.50" --memory="256m" -e PORT=9090 -d kmdevops:latest'
				sh 'sudo ssh -i /home/km/jenkins-ubuntu-docker km@192.168.29.96 docker run --name KMDevOps-DevSecOps-Demo -p 9090:9090 --cpus="0.50" --memory="256m" -e PORT=9090 -d kmdevops:latest'
// 				sshagent(['UHost']) {
// 					//sh 'ssh km@192.168.29.96  uname -a'
// 					//sh 'scp target/bom.xml km@192.168.29.96:/home/km/KMDevOpsSampleWebApp/'
// 					sh 'docker -h ssh://km@192.168.29.96 run --name KMDevOps-DevSecOps-Demo -p 9090:9090 --cpus="0.50" --memory="256m" -e PORT=9090 -d kmdevops:latest'
// 				}
				//sh 'sudo docker run --name KMDevOps-DevSecOps-Demo-$BUILD_NUMBER -p 9090:9090 --cpus="0.50" --memory="256m" -e PORT=9090 -d kmdevops-devsecops-demo:$BUILD_NUMBER'
            		}
        	}
	    
		stage('DAST Scan'){
			steps{
				sshagent(['UHost']) {
					//sh 'ssh km@192.168.29.96  uname -a'
					//sh 'scp target/bom.xml km@192.168.29.96:/home/km/KMDevOpsSampleWebApp/'
					sh 'sudo docker run -t owasp/zap2docker-stable zap-baseline.py -t http://192.168.29.96:9090/ || true'
				}
				//sh 'sudo docker run -t owasp/zap2docker-stable zap-baseline.py -t http://192.168.29.96:9090/ || true'
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
