import { execSync } from 'child_process';

function run(cmd) {
  try {
    console.log(`Running: ${cmd}`);
    execSync(cmd, { stdio: 'inherit' });
  } catch (err) {
    console.error(`Error running: ${cmd}`);
  }
}

function getIds(cmd) {
  try {
    return execSync(cmd).toString().trim().split(/\r?\n/).filter(Boolean);
  } catch {
    return [];
  }
}


// Stop all running containers
const runningContainers = getIds('docker ps -q');
if (runningContainers.length) {
  run(`docker stop ${runningContainers.join(' ')}`);
}

// Remove all containers
const allContainers = getIds('docker ps -aq');
if (allContainers.length) {
  run(`docker rm ${allContainers.join(' ')}`);
}

// Remove all volumes
const allVolumes = getIds('docker volume ls -q');
if (allVolumes.length) {
  run(`docker volume rm ${allVolumes.join(' ')}`);
}

// Build the API service using the development environment variables
run('docker-compose --env-file .env.development build api');

// Start the API service
run('docker-compose --env-file .env.development up -d');
