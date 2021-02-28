# Fly.io Elixir Hiring Project

Hello! This is a hiring project for our [Elixir dev advocate](https://fly.io/blog/we-are-hiring-elixir-developer-advocates/) position. If you apply, we'll ask you to do this project so we can assess your ability to work with Elixir/Phoenix/LiveView. This is a pretty good representation of the type of work we need to do at Fly.io. 

## The purpose

This is a Phoenix/LiveView app that demonstrates LiveView "multiplayer" by letting people collaboratively increment/decrement a counter. We modified [`dwyl/phoenix-liveview-counter-tutorial`](https://github.com/dwyl/phoenix-liveview-counter-tutorial) to add clustering and a click breakdown by region.

You can see it in action here: https://liveview-counter.fly.dev/

If you work as an Elixir dev advocate at Fly.io, this is the type of project we'll want you to produce. It shows how to use LiveView and, because we want to do well as a company, why Fly.io is a good place to deploy a LiveView project.

We'll also want you to blog about it. You can think of the job as "come up with good examples on Fly" and "write about them".

## Hiring project

For hiring purposes, we don't (yet) want you to do a from-scratch project like this. We do want to see that you can work with Elixir, Phoenix, and distributed apps. So we'd like you to improve this project.

When you load liveview-counter.fly.dev, you'll notice there are only one or two regions showing in the output. This is a flaw, it happens because we're using pubsub, each app instance keeps its own count, and these only get communicated when someone clicks and triggers a publish.

Instead, we'd like the demo to do what users would expect at load time. It should show numbers for every region the first time someone visits.

When you run the app locally, you can set a `FLY_REGION` environment variable to "fake" a region. Try `ord` or `sin` or `syd` or `hkg` or `fra`, for example.

You'll need to run two instances of the app _and_ cluster them locally to test your changes. `libcluster` is relatively simple to work with, you might use the [`Epmd`](https://hexdocs.pm/libcluster/Cluster.Strategy.Epmd.html#content) strategy in development mode to cluster two test processes.

We expect this to take about two hours for experience Elixir/Phoenix devs, but you can spend as much time on it as you want if you're still learning.

## Submit your work

1. Clone this repository locally
2. Create a branch for your changes
3. Do some development
4. When you're ready, create a patchset to submit
   * `git diff master <your-branch> > fly-work-sample.patch.txt`
5. Email the patch to jobs+elixir@fly.io (or reply to your existing email chain)

## Evaluation process

Once we receive your patch, we will anonymize it and have three Fly.io engineers evaluate it. This takes 3-5 days and we will let you know as soon as we have results.

## What we care about

We have two specific things we're looking for: 

* Does it show clicks/presence from every region at first load?
* Is clustering in dev mode configured?

Don't waste time on:

* Deploying the app, running it locally is just fine
* Updating the README or writing docs
* Writing tests
* Design / refactoring / other cleanup