// Documenso Admin Signup Automation Script
// This script uses Puppeteer to automate the admin signup process for Documenso
// Usage: node documenso_signup.js [admin_email] [admin_password] [admin_name]

const puppeteer = require('puppeteer');
const fs = require('fs');
const path = require('path');

// Configuration - can be overridden with environment variables or command line args
const config = {
  documensoUrl: process.env.DOCUMENSO_URL || 'https://docs.curiousdev.net',
  adminEmail: process.argv[2] || process.env.ADMIN_EMAIL || 'admin@curiousdev.net',
  adminPassword: process.argv[3] || process.env.ADMIN_PASSWORD || 'StrongPassword123!',
  adminName: process.argv[4] || process.env.ADMIN_NAME || 'Admin User',
  headless: process.env.HEADLESS !== 'false', // Set HEADLESS=false to see browser
  screenshotDir: process.env.SCREENSHOT_DIR || '/tmp/screenshots',
  signatureDataUrl: null // Will be generated dynamically
};

// Ensure screenshot directory exists
if (!fs.existsSync(config.screenshotDir)) {
  fs.mkdirSync(config.screenshotDir, { recursive: true });
}

// Generate a simple signature (a basic scribble)
function generateSignatureDataUrl() {
  const canvas = document.createElement('canvas');
  canvas.width = 300;
  canvas.height = 100;
  const ctx = canvas.getContext('2d');
  
  // Create a simple signature
  ctx.beginPath();
  ctx.lineWidth = 2;
  ctx.strokeStyle = '#000000';
  
  // Draw a simple cursive-like pattern
  ctx.moveTo(50, 70);
  ctx.bezierCurveTo(70, 10, 90, 90, 120, 50);
  ctx.bezierCurveTo(150, 10, 180, 90, 210, 50);
  ctx.bezierCurveTo(240, 20, 260, 70, 280, 50);
  ctx.stroke();
  
  return canvas.toDataURL();
}

async function takeScreenshot(page, name) {
  await page.screenshot({ 
    path: path.join(config.screenshotDir, `${name}.png`),
    fullPage: true 
  });
  console.log(`Screenshot saved: ${name}.png`);
}

async function run() {
  console.log('Starting Documenso admin signup automation...');
  console.log(`Using Documenso URL: ${config.documensoUrl}`);
  console.log(`Admin email: ${config.adminEmail}`);
  
  const browser = await puppeteer.launch({ 
    headless: config.headless,
    args: ['--no-sandbox', '--disable-setuid-sandbox'],
    defaultViewport: { width: 1280, height: 800 }
  });
  
  try {
    const page = await browser.newPage();
    
    // Navigate to Documenso and wait for the page to load
    console.log('Navigating to Documenso...');
    await page.goto(`${config.documensoUrl}/signup`, { waitUntil: 'networkidle2' });
    await takeScreenshot(page, '01-signup-page');
    
    // Check if we're on the signup page
    const currentUrl = page.url();
    if (!currentUrl.includes('/signup')) {
      // We might be redirected if we're already logged in
      if (currentUrl.includes('/dashboard')) {
        console.log('Already logged in. Signing out first...');
        // Try to sign out
        await page.goto(`${config.documensoUrl}/signout`, { waitUntil: 'networkidle2' });
        await page.goto(`${config.documensoUrl}/signup`, { waitUntil: 'networkidle2' });
        await takeScreenshot(page, '02-signup-page-after-signout');
      } else {
        throw new Error(`Unexpected redirect to ${currentUrl}`);
      }
    }
    
    // Wait for name field and fill in admin details
    console.log('Filling signup form...');
    await page.waitForSelector('input[name="name"]');
    await page.type('input[name="name"]', config.adminName);
    await page.type('input[name="email"]', config.adminEmail);
    await page.type('input[name="password"]', config.adminPassword);
    await takeScreenshot(page, '03-filled-form');
    
    // Generate signature
    console.log('Creating signature...');
    const signatureDataUrl = await page.evaluate(generateSignatureDataUrl);
    
    // Find and click the signature field
    const signatureButton = await page.waitForSelector('button[data-testid="draw-signature-button"]');
    await signatureButton.click();
    
    // Wait for signature canvas and draw
    await page.waitForSelector('div[data-testid="signature-dialog"]');
    
    // Inject the signature data URL
    await page.evaluate((dataUrl) => {
      // Find the canvas element in the signature dialog
      const canvasElement = document.querySelector('div[data-testid="signature-dialog"] canvas');
      if (!canvasElement) throw new Error('Canvas element not found');
      
      // Create a new image and load our signature
      const img = new Image();
      img.onload = () => {
        const ctx = canvasElement.getContext('2d');
        ctx.drawImage(img, 0, 0);
        
        // Create and dispatch change event to ensure data is captured
        const event = new Event('change', { bubbles: true });
        canvasElement.dispatchEvent(event);
      };
      img.src = dataUrl;
    }, signatureDataUrl);
    
    // Wait for signature to be drawn
    await page.waitForTimeout(1000);
    await takeScreenshot(page, '04-signature-drawn');
    
    // Click the continue button in the signature dialog
    const continueButton = await page.waitForSelector('div[data-testid="signature-dialog"] button[data-testid="dialog-submit"]');
    await continueButton.click();
    
    // Wait for dialog to close
    await page.waitForFunction(() => {
      return !document.querySelector('div[data-testid="signature-dialog"]');
    });
    
    // Submit the form
    console.log('Submitting signup form...');
    const submitButton = await page.waitForSelector('button[type="submit"]');
    await submitButton.click();
    
    // Wait for redirect to dashboard or email verification page
    await page.waitForNavigation({ waitUntil: 'networkidle2' });
    await takeScreenshot(page, '05-after-submit');
    
    const postSignupUrl = page.url();
    console.log(`Redirected to: ${postSignupUrl}`);
    
    if (postSignupUrl.includes('/dashboard')) {
      console.log('SUCCESS: Admin account created and logged in successfully!');
      
      // Create webhook and API token after signup
      console.log('Setting up webhook and API token...');
      
      // Go to webhooks page
      await page.goto(`${config.documensoUrl}/settings/webhooks`, { waitUntil: 'networkidle2' });
      await takeScreenshot(page, '06-webhooks-page');
      
      // Click the "Create Webhook" button
      const createWebhookButton = await page.waitForSelector('button[aria-label="Create Webhook"]');
      await createWebhookButton.click();
      
      // Wait for the modal
      await page.waitForSelector('div[role="dialog"]');
      
      // Fill webhook form - backend URL
      const webhookUrl = 'http://rentdaddy-backend:8080/webhooks/documenso';
      await page.type('input[name="endpointUrl"]', webhookUrl);
      
      // Generate secret
      const secretField = await page.waitForSelector('input[name="secret"]');
      const randomSecret = Math.random().toString(36).substring(2, 15) + Math.random().toString(36).substring(2, 15);
      await secretField.type(randomSecret);
      
      // Check "document.signed" event
      await page.click('input[name="events.document.signed"]');
      
      // Save webhook
      const saveButton = await page.waitForSelector('button[type="submit"]');
      await saveButton.click();
      
      // Wait for webhook to be created
      await page.waitForSelector('div.text-sm:has-text("Webhook successfully created")');
      await takeScreenshot(page, '07-webhook-created');
      
      console.log(`Created webhook with secret: ${randomSecret}`);
      
      // Now create API token
      await page.goto(`${config.documensoUrl}/settings/api-tokens`, { waitUntil: 'networkidle2' });
      await takeScreenshot(page, '08-api-tokens-page');
      
      // Click "Create API Token" button
      const createTokenButton = await page.waitForSelector('button[aria-label="Create API Token"]');
      await createTokenButton.click();
      
      // Wait for the modal
      await page.waitForSelector('div[role="dialog"]');
      
      // Fill token name
      await page.type('input[name="name"]', 'RentDaddy Integration');
      
      // Create token
      const createButton = await page.waitForSelector('button[type="submit"]');
      await createButton.click();
      
      // Wait for modal with token
      await page.waitForSelector('div[role="dialog"]:has-text("API Token created")');
      
      // Extract token
      const apiToken = await page.evaluate(() => {
        const tokenElement = document.querySelector('div[role="dialog"] code');
        return tokenElement ? tokenElement.textContent : null;
      });
      
      await takeScreenshot(page, '09-api-token-created');
      
      if (apiToken) {
        console.log(`Created API Token: ${apiToken}`);
        
        // Write config to file for the backend to use
        const configOutput = {
          documenso: {
            adminEmail: config.adminEmail,
            webhookSecret: randomSecret,
            apiToken: apiToken
          }
        };
        
        // Write to /tmp directory for the backend to pick up
        fs.writeFileSync('/tmp/documenso_config.json', JSON.stringify(configOutput, null, 2));
        console.log('Config written to /tmp/documenso_config.json');
      } else {
        console.log('Failed to extract API token');
      }
      
    } else if (postSignupUrl.includes('/signup/email-verification')) {
      console.log('PARTIAL SUCCESS: Admin account created, email verification required.');
      console.log('Check email inbox for verification link.');
    } else {
      console.log(`WARNING: Unexpected redirect to ${postSignupUrl}`);
    }
    
    // Final confirmation
    console.log('\nDocumenso admin signup process completed.');
    console.log(`Admin Name: ${config.adminName}`);
    console.log(`Admin Email: ${config.adminEmail}`);
    console.log('Screenshots saved to:', config.screenshotDir);
    
  } catch (error) {
    console.error('Error during signup process:', error);
    // Take screenshot of error state
    try {
      const page = (await browser.pages())[0];
      await takeScreenshot(page, 'error-state');
      console.log('Error screenshot saved as error-state.png');
    } catch (screenshotError) {
      console.error('Failed to capture error screenshot:', screenshotError);
    }
  } finally {
    await browser.close();
  }
}

// Run the automation
run().catch(console.error);