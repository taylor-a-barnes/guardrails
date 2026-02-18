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

### 2. Switch to a development workflow that is customized for use with agentic AI.

Development with assistance from agentic AI represents a major paradigm shift that necessitates fundamental changes in processes and attitudes.
In particular, you will need to adopt a workflow that utilizes your AI agents in an intelligent way.
When first getting started, many users naturally fall into a "vibe-coding" workflow that looks like this:
1. Ask the AI to write some code.
2. Try running the code, and notice that something isn't quite working correctly.
3. Ask the AI to fix the issue.
4. Repeat steps 1-3.

There are many problems with this approach.
When you use a simple, one sentence prompt to ask an LLM to implement a complex and nuanced feature, it is almost guaranteed that you won't get what you want.
The LLM will naturally tend to write the simplest possible code that technically does what you asked for, while assuming happy paths (that is, situations in which everything else is working correctly) and ignoring possible edge cases.
For example, if you say "Write me a parser for XYZ molecular input files", the response from the LLM will likely make many assumptions about the formatting and contents of the XYZ files in question.
In a proper, maintainable implementation that is suitable for distribution, you would need to consider many nuances, including the following:
- What if the file doesn't exist?
- What if the file has unexpected blank lines?
- What if a line is missing expected columns?
- What if a line has extra columns that were not expected?
- What if columns in a line are tab-separated instead of space-separated?
- What if the number of atoms listed in the header does not match the number of atomic coordinates listed in the rest of the file?
- What if some of the atom types don't correspond to real elements?
- What if the file is a trajectory file that contains many frames?
- What should be done with the comment line in the header?

If you're taking the cavalier vibe-coding approach, you aren't even considering these nuances, let alone expressing them to the LLM.
It doesn't matter how good your LLM model is, or how good they become in the future: if you don't express what you want in clear and complete terms, you aren't going to get what you want.
Most of the real work of programming is consumed by dealing with all of the obnoxious edge cases that an untrained mind wouldn't even notice.

There are many workflows that can improve the utilization of AI agents.
As a baseline for getting started, we recommend the following workflow:
1. Create a requirements file for a feature.
2. Generate code to fulfill the requirements file.
3. If something about the new code is incorrect or insufficient, modify the requirements file to increase clarity or completeness.
4. Repeat 2-3 until the feature is satisfactory.

### 3. Your project's requirements files are the only source of truth.

This is another big paradigm shift.
Never write code that isn't directly necessitated by a requirements file.
First change the requirements file, then write the code (either manually or with LLM assistance).
The requirements files must form a complete description of the project that is sufficient to reproduce the behavior of the code from scratch, including full handling of edge cases and unhappy paths.
If the source code doesn't agree with the requirements, the code is wrong.
In practice, this means that as a single-contributor developer, you must follow the sorts of formal design processes normally associated with management of a human development team.
The primary difference is that an LLM is doing the grunt work.

### 4. Take full advantage of modern compilers, linters, etc.

One of the primary disadvantages of working with lower-level languages is that the up-front cost of writing an initial solution is higher.
With an LLM doing much of the work, this disadvantage is substantially mitigated; meanwhile, the benefits of having compile-time validation of the LLM agent's work is massive.
When working with a compiled code, LLM agents can automatically attempt to compile the code, and then iteratively make any necessary corrections until all compiler errors and warnings are resolved.
Many of these same errors would not be caught until runtime when using an interpreted language such as Python or Ruby, and runtime errors are much trickier for both humans and LLMs to notice and debug.

Of particular note, we suggest that Rust is a very strong choice when doing LLM-assisted work, and should be seriously considered when starting new projects.

