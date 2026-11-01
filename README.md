# Accommodation-maintenance-project
MaintenanceApp
Project Title : Student Accomodation Maintenance System

Project description:
The Student Accommodation Maintenance Management System is a software solution designed to improve the way maintenance problems are reported, managed, and tracked within student accommodation.
Currently, students report maintenance issues through WhatsApp messages, phone calls, and face-to-face communication, making it difficult for landlords or accommodation managers to keep track of requests and determine which problems have been resolved or are still outstanding. 
Students also have limited visibility into the progress of their reported issues.The proposed system will provide a centralised platform where students can submit maintenance requests, provide details about the problem, and monitor the status of their requests. Accommodation managers or landlords will be able to view, prioritise, assign, update, and manage maintenance requests from one location.
The system aims to improve communication, accountability, response times, and record-keeping, while providing students with a simple and transparent way to monitor their maintenance issues.

Technologies :
-Flutter
-Asp.Net
-Supabase

Group Members :
Thabethe LJ     220019475
Sithole SF      222071197
Mazwazwa V      220010142
Ncapai L        220045007
Tshabalala Kp   221030087
Davids Jl.      224108179
Mandlazi DL     223029532

 Current Project Stage : Planning and requirements, Feasibility 


 a Flutter mobile app where students report problems with photos, follow progress and confirm whether a repair worked;
an ASP.NET web app where the landlord and approved caretakers view, prioritise and update requests, and manage rooms and tenants;
one shared Supabase backend (PostgreSQL database, authentication and photo storage) used by both apps.

Current project stage: Phase 3 — development, integration and final demonstration (working prototype).

Main features

Student app (Flutter)

Sign up and log in; students are linked to their room automatically when their student number and surname match the landlord's tenant list ("Try again" if they made a typo)
Report a problem in two steps: title, category, description and priority (Low to Urgent), then up to 3 photos
My Requests with status filters and search, request details with photos and a dated status timeline
Confirm a repair ("Yes, it's fixed") or reopen it with a comment
Delete a request reported by mistake, before maintenance has acted on it
In-app notifications for status changes and staff notes; profile, help and support

Landlord and caretaker app (ASP.NET Core MVC)

Staff login by role; caretakers sign up and wait for the landlord's approval, then see only their own building
Overview dashboard: status totals and chart, priorities and upcoming tasks, per property
Maintenance requests: filters, details, photos, and updates (status, priority and notes)
Rooms and occupancy, tenants, CSV tenant import with preview, registration requests, caretaker approval
Staff notifications for new, reopened and resolved requests; staff profile with photo; password reset by email code



├── mobile/      Flutter student app (lib/: models, services, viewmodels, views)
├── web/         ASP.NET Core MVC staff app (Controllers, Models, Services, Views, wwwroot)
├── Documentation.md
└── README.md
