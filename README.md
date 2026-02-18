# Guardrails


## Key Rules of AI-Assisted Programming

### 1. Only ever use agentic AI inside of a Podman container

LLM's are intrinsically vulnerable to prompt injection and data poisoning, allowing even relatively unsophisticated attackers to alter the behavior of the LLM.
Malicious actors can easily hijack an LLM to send them a user's personal information (including ssh keys) or to instruct an LLM agent engage in destructive actions.
*There are no reliable ways of preventing LLMs from falling for these types of attacks.*
If you've used LLM agents before, you've no doubt noticed that they will often ask for permission before executing commands.
Don't let this lull you into a false sense of security - there are many ways around this permission structure.
If you run an LLM agent, you should *assume* that at some point it will take hostile actions.

One of the most important things you can do to protect yourself is to restrict any LLM agents to an isolated container environment that does not have sudo access.
Note that although Docker is currently the most popular containerization option, Docker containers have root access by default and are therefore not a good solution to the LLM security problem.
Instead, The MolSSI recommends using Podman.
Podman containers do not have root access by default, making them a generally better option when security is a concern.
To help you avoid accidentally exposing your entire system to hackers, this repository includes a hook that prevents Claude from answering prompts unless it is run in a container.

Note that containerization is merely a first step in protecting yourself when using LLM agents.
Even when working in a container, you should treat the agent with considerable skepticism.
Among other things, this means that you must:
- Never give it any information you wouldn't give to a stranger.
- Never expose your private ssh keys or other personal information in your LLM container.
- Never give an LLM write access to your remote repository, and do not include GitHub credentials in your LLM container.
- Never push LLM-generated code until you are convinced that it hasn't introduced any exploits into your repository, and only push from outside of the container.
