#! /bin/bash

# ############ Env vars used, set in CI ############################################################
# AWS_ACCESS_KEY=$AWS_ACCESS_KEY_ID
# AWS_SECRET_ACCESS_KEY=$AWS_SECRET_ACCESS_KEY

# AWS_DEFAULT_REGION=$AWS_DEFAULT_REGION
# AWS_ACCOUNT_ID=$AWS_ACCOUNT_ID
# CLUSTER_NAME=$CLUSTER_NAME
# SERVICE_BASENAME=$SERVICE_BASENAME
# #   (i.e. my-app; -dev will get appended for the dev environment, making my-app-dev)
# IMAGE_BASENAME=$IMAGE_BASENAME
# #   (i.e. my-app; -dev will get appended for the dev environment, making my-app-dev)

# ## Env vars generated by Travis
# TRAVIS_BRANCH=$TRAVIS_BRANCH
# TRAVIS_COMMIT=$TRAVIS_COMMIT
# ################################################################################################

pushToEcr () {
    eval $(aws ecr get-login --region $AWS_DEFAULT_REGION)
        
    echo "Pushing $1 to $2"
    docker tag $1 $2:latest
    docker push $2:latest
    docker tag $1 $2:$TRAVIS_COMMIT 
    docker push $2:$TRAVIS_COMMIT 
    echo "Pushed $2"
}

if [ -z "$TRAVIS_PULL_REQUEST" ] || [ "$TRAVIS_PULL_REQUEST" == "false" ]; then
    
    ENV_SUFFIX=""
    if [ "$TRAVIS_BRANCH" == "master" ]; then 
      ENV_SUFFIX="-dev"
    elif [ "$TRAVIS_BRANCH" == "staging" ]; then 
      ENV_SUFFIX="-stg"
    elif [ "$TRAVIS_BRANCH" == "production" ]; then 
      ENV_SUFFIX="-prod"
    else 
      exit 1;  
    fi

    IMAGE_FULLNAME=$IMAGE_BASENAME$ENV_SUFFIX
    IMAGE_URL_BASE=$AWS_ACCOUNT_ID.dkr.ecr.$AWS_DEFAULT_REGION.amazonaws.com/$IMAGE_BASENAME
    #IMAGE_URL=$IMAGE_URL_BASE:$TRAVIS_COMMIT
    SERVICE_FULLNAME=$SERVICE_BASENAME$ENV_SUFFIX

    # Only push a new build/image if dev deploy; staging and production will use that same build (tagged with latest)
    if [ "$TRAVIS_BRANCH" == "master" ]; then
      pushToEcr $IMAGE_FULLNAME $IMAGE_URL_BASE
    fi 

    echo "Deploying $TRAVIS_BRANCH on service $SERVICE_FULLNAME (cluster: $CLUSTER_NAME)"
    
    # This will deploy the build/image tagged with latest from ECR to ECS
    #`deploy-ecs/ecs-deploy.sh -c $CLUSTER_NAME -n $SERVICE_FULLNAME -i $IMAGE_URL_BASE -r $AWS_DEFAULT_REGION --timeout 600
fi 
