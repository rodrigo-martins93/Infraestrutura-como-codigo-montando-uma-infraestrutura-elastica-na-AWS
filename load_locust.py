from locust import FastHttpUser, task

class WebsiteUser(FastHttpUser):

    host = "http://localhost:8089"

    @task
    def index(self):
        self.client.get("/")

