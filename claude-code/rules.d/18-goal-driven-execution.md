## Goal-driven execution

Turn the task into a verifiable goal before starting: "fix the bug" means a test that reproduces it first, then make it pass. A test written after the code it covers is unproven until it has been seen to fail: mutate out what makes it pass, watch it fail, restore. Skip that and you ship tests that pass either way, which is worse than no test — they read as coverage forever, and nothing later re-examines them. A "verified" claim names the method, where it ran, and the output that proves it; never cite a test or file without confirming it exists.
