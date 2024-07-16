echo "`n📦 Initializing Kubernetes cluster...`n"

minikube start --cpus 2 --memory 4g --driver podman --container-runtime=cri-o --profile polar

echo "`n💾 Loading used images `n"

$images = @('docker.io/bitnami/postgresql:15', 'docker.io/rabbitmq:3.11-management', 'docker.io/redis:7')
$i = 1
$images.ForEach({ 
            
        $p = [math]::floor(($i / $images.Length) * 100)
    
        # Start-Sleep -Milliseconds 250
        # Write-Progress -Activity "Loading images" -Status  "Progress: $p% - loading $_" -PercentComplete $p        
        minikube image load "$_" -p polar	
        echo "  * image $_ loaded"              
    
        $i = $i + 1
    })

echo "`n🔌 Enabling NGINX Ingress Controller...`n"

minikube addons enable ingress --profile polar

sleep 30

echo "`n📦 Deploying Keycloak..."

kubectl apply -f services/keycloak-config.yml
kubectl apply -f services/keycloak.yml

sleep 5

echo "`n⌛ Waiting for Keycloak to be deployed..."

while ( (kubectl get pod -l app=polar-keycloak | Measure-Object -line).lines -eq 0) {
    sleep 5
}

echo "`n⌛ Waiting for Keycloak to be ready..."

kubectl wait `
    --for=condition=ready pod `
    --selector=app=polar-keycloak `
    --timeout=300s

echo "`n📦 Deploying PostgreSQL..."

kubectl apply -f services/postgresql.yml

sleep 5

echo "`n⌛ Waiting for PostgreSQL to be deployed..."

while ( (kubectl get pod -l db=polar-postgres | Measure-Object -line).lines -eq 0) {
    sleep 5
}

echo "`n⌛ Waiting for PostgreSQL to be ready..."

kubectl wait `
    --for=condition=ready pod `
    --selector=db=polar-postgres `
    --timeout=180s

echo "`n📦 Deploying Redis..."

kubectl apply -f services/redis.yml

sleep 5

echo "`n⌛ Waiting for Redis to be deployed..."

while ( (kubectl get pod -l db=polar-redis | Measure-Object -line).lines -eq 0) {
    sleep 5
}

echo "`n⌛ Waiting for Redis to be ready..."

kubectl wait `
    --for=condition=ready pod `
    --selector=db=polar-redis `
    --timeout=180s

echo "`n📦 Deploying RabbitMQ..."

kubectl apply -f services/rabbitmq.yml

sleep 5

echo "`n⌛ Waiting for RabbitMQ to be deployed..."

while ( (kubectl get pod -l db=polar-rabbitmq | Measure-Object -line).lines -eq 0) {
    sleep 5
}

echo "`n⌛ Waiting for RabbitMQ to be ready..."

kubectl wait `
    --for=condition=ready pod `
    --selector=db=polar-rabbitmq `
    --timeout=180s

echo "`n📦 Deploying Polar UI..."

kubectl apply -f services/polar-ui.yml

sleep 5

echo "`n⌛ Waiting for Polar UI to be deployed..."

while ( (kubectl get pod -l app=polar-ui | Measure-Object -line).lines -eq 0) {
    sleep 5
}

echo "`n⌛ Waiting for Polar UI to be ready..."

kubectl wait `
    --for=condition=ready pod `
    --selector=app=polar-ui `
    --timeout=180s

echo "`n⛵ Happy Sailing!`n"
