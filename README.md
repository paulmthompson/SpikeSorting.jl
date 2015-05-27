# SpikeSorting.jl
Online spike sorting methods in Julia

Introduction
============

This is a Julia implementation of online spike spike sorting. We are going to be converting methods already available in other languages, probably mostly from Osort since this was designed with real time analysis in mind. Our main goal is to make something that can be used with an Intan RHD2000 board for acquisition:

https://github.com/paulmthompson/Intan.jl

