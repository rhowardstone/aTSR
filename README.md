# aTSR
Agentic test suite refinement (_in progress_)


Created as a project for CSE5095: AI for Software Development (Fall 2025)


```bash
git clone https://github.com/rhowardstone/aTSR.git
cd aTSR
bash src/install_command.sh
```

You may then navigate to your repository of choice, or choose from our three examples:

```bash
bash src/setup_test_repos.sh examples
ls examples/repos_reduced/
```

Once you've navigated to the repo, you may run ```claude```, then ```/refine-tests auto```.

If you are trying to recreate our results, you will want to first run: 

```bash
for n in 1 2 3; do
  bash src/create_benchmark.sh examples/repos_reduced/ bench/bench$n/
  bash src/run_benchmark.sh bench/bench$n/
done
```

to create the three repeats on each of our four test configurations (base,refinement x sonnet,opus)

