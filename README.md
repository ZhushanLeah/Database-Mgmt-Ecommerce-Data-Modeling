# E-Commerce Relational Database Management System (RDBMS)

## Project Overview
This repository contains the complete lifecycle of a custom-built E-Commerce Relational Database Management System. The project simulates a real-world e-commerce environment, handling complex data relationships among customers, sellers, products, orders, payments, and reviews. 

The goal of this project is to demonstrate a robust database architecture, advanced SQL querying, and seamless integration with a frontend application to execute real-time business transactions.

## Tech Stack
* Database Management: PostgreSQL (Version 14+)
* Database Modeling: Entity-Relationship Diagrams (ERD), Relational Algebra
* Key Features: Triggers, Views, Assertions, Indexes, ACID Transactions

## The Development Journey
This project was developed incrementally through a series of rigorous milestones, ensuring data integrity and robust business logic at every step:

* Conceptual & Logical Design:
Starting with business requirements, we designed an ERD and mapped it into a normalized Relational Schema (up to BCNF). This established the foundational entities like Geolocation, Product, Order, and Customer.

* Complex Data Querying & Analysis:
Developed over 20 advanced SQL queries to extract business intelligence. This included multi-table joins, complex aggregations, grouping, subqueries, and set operations to analyze sales performance, inventory turnover, and delivery delays.

* Database Creation & Constraint Enforcement:
Implemented the physical database using PostgreSQL. We enforced strict data integrity using Primary/Foreign Key constraints, attribute/tuple-level constraints, and custom PL/pgSQL Triggers (acting as Assertions) to handle dynamic rules like stock reduction and payment validation.

* ACID Transactions:
Engineered robust transactional scripts to handle real-world scenarios, such as safely placing an order (inserting records while automatically updating stock and status via triggers) and canceling orders (restocking inventory and cascading deletions).

* Application Integration:
Developed a user-facing application connected directly to our PostgreSQL database. The application provides an interactive interface to execute our core business transactions and demonstrates how data changes correctly persist in the backend.

## How to Run the Project
* Step A (Setup Database): Execute the creation script (Assignment5_creation.sql) to build the schema, constraints, and triggers.
* Step B (Populate Data): Run the insertion script (Assignment5_insertion.sql) to load the mock data.
* Step C (Run Application): python app.py

## Project Team
* Zhushan He
* Selvi Lesmana Putri
* Alhagie Kijera
* Isaac Ebu-Danso
