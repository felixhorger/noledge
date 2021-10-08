Noledge - Structuring knowledge
===============================

**Work in progress, not ready for use**


Aim
---

- Store information in an interactive graph.
- Quickly find the information needed.
- Flatten the learning curve for beginners (origin of the name: no ledge).

The need for such a tool is derived from the following facts

- Students have to acquire more information in shorter time.
- Once learned, keeping every useful insight in mind is impossible.
- Students ask similar questions, consider the success of FAQs.
- Experts are vital, how to ensure that all knowledge is passed on?
- Being new in a field of research, where to start, which direction?
- There is no unified solution, not even on small scales (e.g. inside scientific groups).
- Most documentations are either non-existent, insufficient or too detailed for beginners.
- Mostly, knowledge cannot be brought into a sequential form without compromising mobility (scroll-scroll...).
- Instead, information can be organised into a directed, possibly cyclic graph.


Expected Functionality
----------------------

- Flexibly define graph structure (e.g. in python or json), enabling source control.
- Nodes' contents are generated with LaTex.
- Visualisation and interactive traversal.


Manual
------


Entry is a directory with at least the files content.tex and graph.gv.
Can have subdirectories containing more entries.
Note that the graph's name must be G (symptom: hyperlinks in graphs not present).

=item -
Requires a single directory as cmd-line argument.
This directory is transversed recursively and whenever a pair of files
"content.tex" (LaTex) and "graph.gv" (GraphViz) is found, an HTML (+CSS) page is generated.

=item -
These files can contain any valid LaTex- respectively Graphviz-code.

=item -
The user can insert hyperlinks in the tex file (LaTex package hyperref) and the graph (URL attribute)
that point to other entries.
Note that by default, a local, relative path is assumed (use file:// and https:// for fine-grained control).

Use absolute paths for everything outside the repository, otherwise relative.
Links to files which are in non-child folders will be lost upon move.
