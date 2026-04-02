# AI Dev Agent Workflow Task List

## Phase 1: Request Intake (Jira)
- [ ] Create a custom field in Jira for "Target GitLab Repo" (Select List - single choice)
- [ ] Add the custom field to the project issue creation screen
- [ ] Create Jira Webhook pointing to the newly generated n8n Webhook URL
- [ ] Configure Jira Webhook to trigger on "Issue Created"

## Phase 2: Automation Router (n8n)
- [ ] Create a new n8n Workflow
- [ ] Add a Webhook Trigger node (Method: POST) and copy the Test URL
- [ ] Add a Code/Set node to parse incoming Jira JSON to extract Issue Key, Summary, Description, and Target Repo
- [ ] Add an HTTP Request node to forward the parsed JSON payload to the Agent Orchestrator endpoint on your VM

## Phase 3: Agent Orchestrator (Linux VM)
- [ ] Set up Python environment on the Linux VM (`ai-orchestrator` directory structure)
- [ ] Install required Agent frameworks and utilities (e.g., `fastapi`, `uvicorn`, `google-genai`, `gitpython`, `python-gitlab`)
- [ ] Create an API endpoint (e.g., using FastAPI) to receive the n8n POST request
- [ ] Expose the internal VM port to receive traffic from n8n (or configure reverse proxy like Nginx)

## Phase 4: Gemini Agent Development
- [ ] Configure Gemini API credentials securely in the Orchestrator environment
- [ ] Implement Git operations logic: clone the Target Repo, create branch named `feature/<jira-key>`
- [ ] Implement Context Injection logic: read repository files to provide code context to Gemini
- [ ] Implement LLM Invocation logic: Send the user request (Jira description) and codebase to Gemini
- [ ] Implement File Modification logic: write code changes to local cloned repo files based on Gemini's output

## Phase 5: GitLab Integration
- [ ] Create a GitLab Personal Access Token (PAT) for the local Git client
- [ ] Implement Git commit and push logic using GitPython
- [ ] Use GitLab REST API (via `python-gitlab`) to automatically open a Merge Request

## Phase 6: Feedback Loop (Jira Update)
- [ ] Configure Jira API credentials in Orchestrator (or redirect final webhook back to n8n to handle this)
- [ ] Post a comment on the Jira ticket containing the GitLab MR Link
- [ ] Transition the Jira ticket status to "In Review" or "Code Complete" Using Jira API
