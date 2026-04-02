# Comprehensive Guide: Jira to GitLab Gemini Agent Automation

This guide explains how to build a fully automated AI coding pipeline where Jira tasks trigger an orchestrator on a Linux VM to spawn Gemini agents that write code, submit it as a Merge Request in GitLab, and report back to Jira.

## Architecture Overview

1. **Jira:** Source of truth. Users create tickets specifying the issue and the target repository.
2. **n8n:** The middleware. Catches the Jira event, formats the payload, and triggers the VM.
3. **Agent Orchestrator:** A lightweight API server (e.g., Python FastAPI) running on your Linux VM that receives the structured command.
4. **Gemini Agent:** The "brain" powered by Google's Gemini that reads the code, modifies files, and executes Git commands.

---

## Step 1: Set up Jira 
Since you have one Jira project for multiple repositories, we need to explicitly link a ticket to a repo.

1. **Create Repo Field:** Go to Jira `Settings -> Issues -> Custom Fields -> Create custom field`. Choose "Select List (single choice)" and name it `Target GitLab Repo`. Add your repo names/URLs as dropdown options.
2. **Assign to Screen:** Add this new field to your Project's default issue screen.
3. **Draft Webhook:** We will come back to Jira to add the Webhook URL once n8n is ready.

---

## Step 2: Set up n8n (The Middleware)
n8n acts as the reliable message queue and router.

1. Create a new Workflow in n8n.
2. Add a **Webhook** node (Method: POST, wait for test event). Copy the Test URL.
3. **Back to Jira:** Go to `Settings -> System -> Webhooks -> Create Webhook`. Paste the n8n URL. Select "Issue: Created" and save.
4. Issue a test ticket in Jira to trigger the n8n Webhook.
5. In n8n, add a **Set** node (or Code node) to extract:
   - `Issue Key` (e.g., PROJ-123)
   - `Description` (The task instructions)
   - `Target GitLab Repo` (From your custom field)
6. Add an **HTTP Request** node to POST this cleaned-up JSON to your Linux VM orchestrator.

---

## Step 3: Build the Agent Orchestrator (Linux VM)
Your VM needs a listener to receive the job from n8n. Python with FastAPI is excellent for this.

1. On your VM, create a directory for the orchestrator: 
   ```bash
   mkdir ai-orchestrator && cd ai-orchestrator
   ```
2. Set up a virtual environment and install dependencies: 
   ```bash
   python3 -m venv venv
   source venv/bin/activate
   pip install fastapi uvicorn google-genai gitpython python-gitlab
   ```
3. Create an `app.py` script that exposes a `/trigger-agent` POST endpoint:
   ```python
   from fastapi import FastAPI
   from pydantic import BaseModel

   app = FastAPI()

   class TaskPayload(BaseModel):
       issue_key: str
       repo: str
       description: str

   @app.post("/trigger-agent")
   def start_agent(payload: TaskPayload):
       # Process the Jira task payload
       # 1. Clone Repo using GitPython
       # 2. Run Gemini Agent logic
       # 3. Create MR using python-gitlab
       # 4. Update Jira using rest API
       
       return {"status": f"Agent triggered successfully for {payload.issue_key}"}
   ```
4. Run the server:
   ```bash
   uvicorn app:app --host 0.0.0.0 --port 8000
   ```

---

## Step 4: The Agent Logic (Gemini & Git)
Inside the orchestrator, you will script the actual agent behavior.

1. **Git Clone & Branch:** Use `GitPython` to clone the Target Repo into a temporary directory on the VM. Create a new branch: `feature/{issue_key}`.
2. **Context Gathering:** Have Python read the relevant source files from the cloned repository.
3. **Gemini Invocation:** Send the source code and the Jira instructions to the Gemini API (`gemini-2.5-pro` is recommended for coding tasks). Prompt it to return the exact modified code or diffs.
4. **Write Changes:** Overwrite the local files on the VM with Gemini's response.
5. **Git Push:** Stage, commit, and push the branch to GitLab.

---

## Step 5: GitLab Merge Request & Jira Feedback
Once the code is pushed, use API calls to knit the tools together.

1. **Create MR:** Use the `python-gitlab` library to authenticate with a Personal Access Token and create a Merge Request from `feature/{issue_key}` to `main` (or develop).
2. **Update Jira:** Use the Jira REST API (or an n8n Jira node) to add a comment to the original Jira issue: *"Agent has completed the draft. Review the Merge Request here: [Link]"*. Then transition the issue status to `In Review`.
