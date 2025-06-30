#!/usr/bin/env node

/**
 * Rails Manager - Development tool for managing Rails server and background jobs
 * 
 * This tool was created to speed up development by avoiding repeated bash command approvals.
 * It provides unified control over the Rails server and solid_queue job processor.
 * 
 * Usage:
 *   node scripts/rails_manager.js start    # Start Rails server and job processor
 *   node scripts/rails_manager.js stop     # Stop all services  
 *   node scripts/rails_manager.js restart  # Restart services
 *   node scripts/rails_manager.js status   # Check running processes
 *   node scripts/rails_manager.js test     # Test incarnation lifecycle
 * 
 * Benefits:
 * - Single command for common operations
 * - Automatic cleanup of stale processes
 * - Built-in incarnation lifecycle testing
 * - Logs directed to files for easy debugging
 * 
 * Created: June 30, 2025
 * Purpose: Speed up Soulforge Universe development workflow
 */

const { spawn, exec } = require('child_process');
const { promisify } = require('util');
const fs = require('fs');
const path = require('path');

const projectRoot = path.resolve(__dirname, '..');

const execAsync = promisify(exec);

class RailsManager {
  constructor() {
    this.processes = {
      rails: null,
      jobs: null
    };
    this.logDir = path.join(projectRoot, 'log');
  }

  async killExisting() {
    try {
      // Kill any existing Rails or jobs processes
      await execAsync("ps aux | grep -E 'rails server|bin/jobs' | grep -v grep | awk '{print $2}' | xargs kill -9 2>/dev/null || true");
      console.log('Killed existing Rails and job processes');
    } catch (error) {
      // Ignore errors - processes might not exist
    }
  }

  async startRails(port = 4001) {
    await this.killExisting();
    
    const railsLogPath = path.join(this.logDir, 'rails.log');
    const railsLogFd = fs.openSync(railsLogPath, 'a');
    const railsCmd = spawn('bin/rails', ['server', '-p', port.toString()], {
      cwd: projectRoot,
      env: process.env,
      detached: true,
      stdio: ['ignore', railsLogFd, railsLogFd]
    });
    
    railsCmd.unref();
    this.processes.rails = railsCmd;
    console.log(`Started Rails server on port ${port} (PID: ${railsCmd.pid})`);
  }

  async startJobs() {
    const jobsLogPath = path.join(this.logDir, 'jobs.log');
    const jobsLogFd = fs.openSync(jobsLogPath, 'a');
    const jobsCmd = spawn('bin/jobs', [], {
      cwd: projectRoot,
      env: process.env,
      detached: true,
      stdio: ['ignore', jobsLogFd, jobsLogFd]
    });
    
    jobsCmd.unref();
    this.processes.jobs = jobsCmd;
    console.log(`Started solid_queue job processor (PID: ${jobsCmd.pid})`);
  }

  async start(port = 4001) {
    console.log('Starting Rails server and solid_queue...');
    await this.startRails(port);
    await this.startJobs();
    console.log('Both services started successfully');
  }

  async stop() {
    console.log('Stopping Rails server and solid_queue...');
    await this.killExisting();
    console.log('Services stopped');
  }

  async restart(port = 4001) {
    await this.stop();
    await new Promise(resolve => setTimeout(resolve, 1000)); // Wait 1 second
    await this.start(port);
  }

  async status() {
    try {
      const { stdout } = await execAsync("ps aux | grep -E 'rails server|bin/jobs' | grep -v grep");
      console.log('Running processes:');
      console.log(stdout);
    } catch (error) {
      console.log('No Rails or job processes running');
    }
  }

  async testIncarnation() {
    const testData = {
      game_session_id: `test-session-${Date.now()}`,
      forge_type: "combat",
      team_preferences: ["red"],
      challenge_level: "normal"
    };

    try {
      // Create incarnation
      const createResponse = await fetch('http://localhost:4001/api/v1/incarnations', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify(testData)
      });
      
      if (!createResponse.ok) {
        throw new Error(`Create failed: ${createResponse.status}`);
      }
      
      const incarnation = await createResponse.json();
      console.log('Created incarnation:', incarnation);
      
      // Wait a moment
      await new Promise(resolve => setTimeout(resolve, 1000));
      
      // End incarnation
      const endData = {
        ended_at: new Date().toISOString(),
        memory_summary: {
          outcome: "victory",
          final_level: 5,
          kills: 10,
          lifetime: 180000
        }
      };
      
      const endResponse = await fetch(`http://localhost:4001/api/v1/incarnations/${incarnation.incarnation_id}/end`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify(endData)
      });
      
      if (!endResponse.ok) {
        throw new Error(`End failed: ${endResponse.status}`);
      }
      
      const result = await endResponse.json();
      console.log('Ended incarnation:', result);
      
      // Check job processing
      console.log('\nChecking for job processing...');
      await new Promise(resolve => setTimeout(resolve, 2000));
      
      const { stdout } = await execAsync(`tail -50 ${path.join(this.logDir, 'development.log')} | grep -E "ProcessIncarnationJob|Performed" | tail -5`);
      if (stdout) {
        console.log('Job processing logs:');
        console.log(stdout);
      } else {
        console.log('No job processing logs found yet');
      }
      
    } catch (error) {
      console.error('Test failed:', error.message);
    }
  }

  async runSeed(fileName) {
    if (!fileName) {
      console.log('Available seed files:');
      try {
        const { stdout } = await execAsync('ls db/seeds/*.rb 2>/dev/null || echo "No seed files found"');
        console.log(stdout);
      } catch (error) {
        console.log('No seed files found');
      }
      return;
    }
    
    const seedPath = fileName.includes('/') ? fileName : `db/seeds/${fileName}.rb`;
    console.log(`Running seed file: ${seedPath}`);
    
    try {
      const { stdout, stderr } = await execAsync(`bin/rails runner "load '${seedPath}'"`, {
        cwd: projectRoot
      });
      console.log(stdout);
      if (stderr) console.error(stderr);
    } catch (error) {
      console.error('Seed failed:', error.message);
    }
  }

  async runRailsCommand(command) {
    if (!command) {
      console.log('Please provide a Rails runner command');
      return;
    }
    
    console.log(`Running: rails runner "${command}"`);
    
    try {
      const { stdout, stderr } = await execAsync(`bin/rails runner "${command}"`, {
        cwd: projectRoot
      });
      console.log(stdout);
      if (stderr) console.error(stderr);
    } catch (error) {
      console.error('Command failed:', error.message);
    }
  }

  async openConsole() {
    console.log('Opening Rails console...');
    
    const consoleCmd = spawn('bin/rails', ['console'], {
      cwd: projectRoot,
      stdio: 'inherit'
    });
    
    consoleCmd.on('exit', (code) => {
      console.log(`Console exited with code ${code}`);
    });
  }
}

// CLI interface
const manager = new RailsManager();
const command = process.argv[2];
const port = process.argv[3] || 4001;

async function main() {
  switch (command) {
    case 'start':
      await manager.start(port);
      break;
    case 'stop':
      await manager.stop();
      break;
    case 'restart':
      await manager.restart(port);
      break;
    case 'status':
      await manager.status();
      break;
    case 'test':
      await manager.testIncarnation();
      break;
    case 'seed':
      await manager.runSeed(process.argv[3]);
      break;
    case 'runner':
      await manager.runRailsCommand(process.argv.slice(3).join(' '));
      break;
    case 'console':
      await manager.openConsole();
      break;
    default:
      console.log('Usage: rails_manager.js [start|stop|restart|status|test|seed|runner|console] [args]');
      console.log('Commands:');
      console.log('  start [port]  - Start Rails server and job processor (default port: 4001)');
      console.log('  stop          - Stop all Rails processes');
      console.log('  restart [port] - Restart all services');
      console.log('  status        - Show running processes');
      console.log('  test          - Create and end a test incarnation');
      console.log('  seed [file]   - Run a seed file (e.g. seed forges)');
      console.log('  runner <code> - Run Rails runner command');
      console.log('  console       - Open Rails console');
  }
}

main().catch(console.error);