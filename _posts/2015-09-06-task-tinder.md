Have you ever been in a decision deadlock? One of those situations where you have to prioritize things but they seem impossible to sort? 

Imagine three simple items on your To Do list:

**To Do**

- Write blog post
- Exercise
- Beer with friends

You consider all three and how they relate to each other. Writing a blog post is obviously more important than to exercise. And you want to exercise before you meet your friends. However a beer with your friends seems more important than writing the blog post (You don't have to agree, it's just an example to illustrate a point). 

Unsure where to start, you draw a diagram

![Write->Exercise->Beer->Write](/media/images/task_tinder_1.png)

Rearranged it's just a circle and it becomes obvious that it doesn't matter where you start (ignoring any other factors like gym opening hours and blogging drunk). 

![Write->Exercise->Beer->Write](/media/images/task_tinder_2.png)

So you settle for 

1. Write
2. Exercise
3. Beer

The story becomes slightly more complicated if you want to invite your friends to your place and you need to clean up before they come over. You hate to admit it, but cleaning is also more important than to exercise.

![Write->Exercise<-Cleaning->Beer](/media/images/task_tinder_3.png)

Now you're completely lost. What to do first? Cleaning is more important than exercise, exercise is important than beer, but beer is not more important than cleaning. But, but, but...how can that be? If A => B and B => C, shouldn't A => C?! Well, real life is a bitch and not all relationships are [transitive](https://en.wikipedia.org/wiki/Transitive_relation). The "Importance" relationship is one of these.

Gladly you're not stuck in this situation, unable to do anything: It's still possible to order all the items in an intransitive set in a way that every item is more important (or whatever the relationship may be) than the following. To find such a solution one needs to find a path connecting all items in the graph without hitting an item twice - such a path is called Hamiltonian path.

For the above example a solution would be:

1. Write
2. Clean
3. Exercise
4. Beer

For larger sets the graph drawing becomes a mess (believe me) and the path finding really tricky. Luckily there are papers describing algorithms doing exactly that. [I implemented one - go and try it out](https://rawgit.com/sebastianludwig/semi_heap_sort/master/src/demo.html). Often there's more than one solution and sometimes the results may be counterintuitive. It seems to help to prime the result by putting the most important item first in your list.

Please leave a comment what you think!
