def call(Map config = [:]) {
    sh "echo Hello Spyro Participants to the DevOps ${config.name}."
}
