# Purpose

It's important to keep our Testing Pipeline insync with our Development Workflow.

However, we do _not_ necessarily want to install all our Development dependencies into our Testing Pipeline (as it wastes time and resources).

Hence, Devbox [suggested](https://github.com/jetify-com/devbox/issues/1926) using plugins to concolidate shared dependencies between these two workflow and they can use their respective devbox.json to install their workflow specific dependencies.
