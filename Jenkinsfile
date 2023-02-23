pipeline 
{
    options 
    {
        timestamps()
    }
    agent any
    environment
    {
        LOG = ''
        TAG_testing = ''
        STAGE = ''
        TAG_ECR = ''
        NEWEST = ''
        VER_CHECK = 'false'
        SKIP = 'false'
        PREFIX = ''
        NEWEST_MAJOR = ''
        NEWEST_MINOR = ''
        PREFIX_MAJOR = ''
        PREFIX_MINOR = ''
    }
    stages 
    {
        stage("Checkout") 
        {
            steps 
            {
                script 
                {
                    STAGE = 'Checkout'
                }
                deleteDir()
                checkout scm
                script 
                {
                    // REPO IS PUBLIC SO WE DO NOT NEED TO USE LOGIN AND PASSWORD FOR GIT, BUT IF IT WAS PRIVATE IT WOULD LOOK LIKE THIS:
                    // withCredentials([gitUsernamePassword(credentialsId: '<id>', gitToolName: 'Default')]) { 
                    //     sh "git fetch https://github.com/maciob/task-rekrutacja --tags"
                    // }
                    // LOG = sh(returnStdout: true, script:"git log --oneline | head -1 | cut -d ')' -f2").trim()
                    // NEED TO FETCH THE TAGS
                    sh "git fetch https://github.com/maciob/task-rekrutacja --tags"
                }
            }
        }
        stage('Build&Run') 
        {
            steps 
            {
                script 
                {
                    STAGE = 'Build&Run'
                    sh "docker-compose up -d --build"
                }
            }
        }
        stage('Tests') 
        {
            steps 
            {
                script 
                {
                    STAGE = 'Tests'
                    // HERE COMES THE TESTING PHASE
                    sh "docker-compose down"
                }
            }
        }
        stage('Calculate TAG') 
        {
            when{
                anyOf
                {
                    // ONLY ON A MASTER BRANCH THERE WILL BE TAGGING
                    branch "master"
                }
            }
            steps 
            {
                script 
                {
                    // I ASSUMED THAT THERE SHOULD BE A TAGGING SYSTEM, SO COMMITER NEEDS TO GIVE MAJOR AND MINOR TAG IN THE COMMIT LIKE 1.1 AND THEN PATCH WILL BE CALCULATED
                    STAGE = 'Calculate TAG'
                    PREFIX = sh(returnStdout: true, script:"echo '${LOG}' | cut -d ' ' -f2").trim()
                    try {  
                        PREFIX = "${PREFIX}" as float;  
                        PREFIX_MAJOR = sh(returnStdout: true, script:"echo '${PREFIX}' | cut -d '.' -f1").trim()
                        PREFIX_MINOR = sh(returnStdout: true, script:"echo '${PREFIX}' | cut -d '.' -f2").trim()
                        PREFIX_MAJOR = "${PREFIX_MAJOR}" as int;  
                        PREFIX_MINOR = "${PREFIX_MINOR}" as int;  
                    } catch(exc){  
                        SKIP = 'true';  
                        sh "echo 'ERROR no version specified'" 
                        return 'ERROR no version specified'
                    }  
                    ORIGINAL = sh(returnStdout: true, script:"git tag --sort=creatordate | grep v.${PREFIX} | tail -1 | cut -d '.' -f2-4").trim()
                    NEWEST = sh(returnStdout: true, script:"git tag --sort=v:refname | tail -1 | cut -d '.' -f2-3").trim()
                    NEWEST = "${NEWEST}" as float;  
                    NEWEST_MAJOR = sh(returnStdout: true, script:"echo '${NEWEST}' | cut -d '.' -f1").trim()
                    NEWEST_MINOR = sh(returnStdout: true, script:"echo '${NEWEST}' | cut -d '.' -f2").trim()
                    NEWEST_MAJOR = "${NEWEST_MAJOR}" as int;  
                    NEWEST_MINOR = "${NEWEST_MINOR}" as int;  

                    try
                    {
                        SUFFIX = sh(returnStdout: true, script:"echo '${ORIGINAL}' | cut -d '.' -f3 ").trim()
                        SUFFIX = "${SUFFIX}" as int
                        SUFFIX = SUFFIX + 1
                        TAG_testing = sh(returnStdout: true, script:"echo 'v.${PREFIX}.${SUFFIX}'").trim()
                        TAG_ECR = sh(returnStdout: true, script:"echo '${PREFIX}.${SUFFIX}'").trim()
                        sh "echo '${TAG_testing}'"
                    }
                    catch(exc)
                    {             
                        TAG_testing = sh(returnStdout: true, script:"echo 'v.${PREFIX}.0'").trim()
                        TAG_ECR = sh(returnStdout: true, script:"echo '${PREFIX}.0'").trim()
                        sh "echo '${TAG_testing}'"                   
                    }  
                }
            }
        }
        stage('Deploy to ECR')
        {
            when{
                expression { env.BRANCH_NAME=="master" && SKIP == 'false'}
            }
            steps 
            {
                script 
                {
                    STAGE = 'Deploy to ECR'
                    sh "aws ecr get-login-password --region eu-west-2 | docker login --username AWS --password-stdin 644435390668.dkr.ecr.eu-west-2.amazonaws.com"
                    sh "docker tag task-rekrutacja_master_webserver:latest 644435390668.dkr.ecr.eu-west-2.amazonaws.com/magisterka-front:${TAG_ECR}"
                    sh "docker push 644435390668.dkr.ecr.eu-west-2.amazonaws.com/magisterka-front:${TAG_ECR}"
                    if(PREFIX_MAJOR > NEWEST_MAJOR || (PREFIX_MAJOR == NEWEST_MAJOR && PREFIX_MINOR >= NEWEST_MINOR))
                    {
                        sh "docker tag task-rekrutacja_master_webserver:latest 644435390668.dkr.ecr.eu-west-2.amazonaws.com/magisterka-front:latest"
                        sh "docker push 644435390668.dkr.ecr.eu-west-2.amazonaws.com/magisterka-front:latest"
                        VER_CHECK = 'true'
                        sh 'echo "TRUE"'
                    }
                }
            }
        }
        stage('GIT TAG')
        {
            when{
                expression { env.BRANCH_NAME=="master" && SKIP == 'false'}
            }
            steps 
            {
                script 
                {
                    STAGE = 'GIT TAG'
                    sh 'git clean -f -x'
                    sh "git tag ${TAG_testing}"
                    withCredentials([gitUsernamePassword(credentialsId: '781630fc-34c9-4810-9226-e844ac17971c', gitToolName: 'Default')]) { 
                        sh "git push https://github.com/maciob/task-rekrutacja --tags"
                    }
                }
            }
        }
    }
    post 
    {
        failure
        {
            emailext recipientProviders: [culprits()], subject: 'Build failure', body: 'Sadge, your build failed at "${STAGE}" with ${BUILD_STATUS}.', attachLog: true
        }
        success
        {
            emailext recipientProviders: [culprits()], subject: 'Build successful', body: 'POG, you are the man.', attachLog: true
        }
    }
}