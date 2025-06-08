#!/usr/bin/env node

// Simple Manual Test Script for Question Display Server
// This script starts the server and provides copy-paste commands for testing

const http = require('http');
const { spawn } = require('child_process');

const PORT = 2900;

// ANSI color codes
const colors = {
  reset: '\x1b[0m',
  bright: '\x1b[1m',
  red: '\x1b[31m',
  green: '\x1b[32m',
  yellow: '\x1b[33m',
  blue: '\x1b[34m',
  cyan: '\x1b[36m'
};

console.log(`${colors.blue}${colors.bright}🚀 Question Display Server - Simple Manual Test${colors.reset}`);
console.log('='.repeat(50));

// Check if port is in use
function checkPort() {
  return new Promise((resolve) => {
    const testServer = http.createServer();
    testServer.listen(PORT)
      .on('listening', () => {
        testServer.close();
        resolve(true);
      })
      .on('error', () => {
        resolve(false);
      });
  });
}

// Wait for server to be ready
function waitForServer(retries = 10) {
  return new Promise((resolve, reject) => {
    const check = () => {
      const req = http.get(`http://localhost:${PORT}/`, (res) => {
        resolve(true);
      });
      req.on('error', () => {
        if (--retries > 0) {
          setTimeout(check, 1000);
        } else {
          reject(new Error('Server failed to start'));
        }
      });
    };
    check();
  });
}

async function main() {
  try {
    // Check if port is available
    const portAvailable = await checkPort();
    if (!portAvailable) {
      console.log(`${colors.red}❌ Port ${PORT} is already in use${colors.reset}`);
      console.log(`${colors.yellow}   Please stop any existing servers and try again${colors.reset}`);
      process.exit(1);
    }

    console.log(`${colors.cyan}📋 Starting server on port ${PORT}...${colors.reset}`);
    
    // Start the server
    const serverProcess = spawn('node', ['index.js'], {
      stdio: ['inherit', 'inherit', 'inherit']
    });

    // Handle cleanup
    process.on('SIGINT', () => {
      console.log(`\n${colors.yellow}🧹 Stopping server...${colors.reset}`);
      serverProcess.kill('SIGTERM');
      process.exit(0);
    });

    process.on('SIGTERM', () => {
      serverProcess.kill('SIGTERM');
      process.exit(0);
    });

    // Wait for server to be ready
    try {
      await waitForServer();
      console.log(`${colors.green}✅ Server is ready!${colors.reset}\n`);
    } catch (error) {
      console.log(`${colors.red}❌ ${error.message}${colors.reset}`);
      serverProcess.kill('SIGTERM');
      process.exit(1);
    }

    // Display manual test instructions
    displayTestInstructions();

    // Keep the script running
    serverProcess.on('exit', (code) => {
      if (code !== 0) {
        console.log(`${colors.red}❌ Server exited with code ${code}${colors.reset}`);
      } else {
        console.log(`${colors.green}✅ Server stopped cleanly${colors.reset}`);
      }
      process.exit(code);
    });

  } catch (error) {
    console.log(`${colors.red}❌ Error: ${error.message}${colors.reset}`);
    process.exit(1);
  }
}

function displayTestInstructions() {
  console.log(`${colors.blue}${colors.bright}🧪 Manual Testing Instructions${colors.reset}`);
  console.log('='.repeat(30));
  console.log('');
  
  console.log(`${colors.yellow}📋 Test 1: True/False Question${colors.reset}`);
  console.log('   Copy and paste this command in a new terminal:');
  console.log('');
  console.log(`${colors.green}   curl -X POST -H "Content-Type: application/json" \\${colors.reset}`);
  console.log(`${colors.green}        -d '{"question":"Is the sky blue?","options":["True","False"]}' \\${colors.reset}`);
  console.log(`${colors.green}        http://localhost:${PORT}/display-question${colors.reset}`);
  console.log('');

  console.log(`${colors.yellow}📋 Test 2: Multiple Choice Question${colors.reset}`);
  console.log('   Copy and paste this command in a new terminal:');
  console.log('');
  console.log(`${colors.green}   curl -X POST -H "Content-Type: application/json" \\${colors.reset}`);
  console.log(`${colors.green}        -d '{"question":"What is 2 + 2?","options":["3","4","5","6"]}' \\${colors.reset}`);
  console.log(`${colors.green}        http://localhost:${PORT}/display-question${colors.reset}`);
  console.log('');

  console.log(`${colors.yellow}📋 Test 3: Long Question${colors.reset}`);
  console.log('   Test with a longer question:');
  console.log('');
  console.log(`${colors.green}   curl -X POST -H "Content-Type: application/json" \\${colors.reset}`);
  console.log(`${colors.green}        -d '{"question":"This is a very long question that tests how the dialog handles longer text content","options":["Short","Medium answer","Very long answer option"]}' \\${colors.reset}`);
  console.log(`${colors.green}        http://localhost:${PORT}/display-question${colors.reset}`);
  console.log('');

  console.log(`${colors.yellow}📋 Test 4: Error Handling${colors.reset}`);
  console.log('   Test invalid endpoint:');
  console.log('');
  console.log(`${colors.green}   curl http://localhost:${PORT}/invalid${colors.reset}`);
  console.log(`${colors.cyan}   (Should return: "Not Found")${colors.reset}`);
  console.log('');

  console.log(`${colors.blue}💡 Expected Results:${colors.reset}`);
  console.log(`${colors.cyan}   • Each POST should return: "Question displayed"${colors.reset}`);
  console.log(`${colors.cyan}   • A dialog box should appear on your screen${colors.reset}`);
  console.log(`${colors.cyan}   • Your selection will be logged in this terminal${colors.reset}`);
  console.log(`${colors.cyan}   • Press Ctrl+C to stop the server when done${colors.reset}`);
  console.log('');

  console.log(`${colors.yellow}🔍 Watch this terminal for user selection logs!${colors.reset}`);
  console.log('');
}

// Start the application
main().catch(console.error);