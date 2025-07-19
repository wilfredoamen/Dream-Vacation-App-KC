# Dream Vacation App – Dockerized Full-Stack Project

This project demonstrates how to containerize a full-stack Dream Vacation App using **Docker** and **Docker Compose**. It consists of a React frontend, a Node.js backend, and a PostgreSQL database.

---
## Technologies Used
- **Frontend**: React
- **Backend**: Node.js with Express
- **Database**: PostgreSQL
- **External API**: REST Countries API

---
### Step 1: Create a PostgreSQL database locally, connect your backend and frontend to it, and test the Dream Vacation App.

1. **Install PostgreSQL Locally, If you don’t have PostgreSQL installed yet.**

- On Windows:
[Download installer PostgreSQL Using This Link](https://www.postgresql.org/download/windows/)

  During install, use:

     - Username: postgres

     - Password: your_postgreSQL_password
2. **Create the Database.** 

- Using the terminal:
Open SQL Shell (psql) and enter:

  `CREATE DATABASE dreamvacations;`
  to create a database name dreamvacations.

  ![image1](./img/img1.png)
  *Img1:Shows the database and user_name created*

3. **Update Backend/.env file.**
    
    In your backend directory, edit the .env file with:

    `DATABASE_URL=postgresql://admin:postgres:your_password@localhost:5432/dreamvacations
    PORT=3001
    COUNTRIES_API_BASE_URL=https://restcountries.com/v3.1`

    Also Update your backend/server.js to have current user,host, database,password and port.

4. **Update Frontend (if applicable).**

   If the frontend needs to call the backend, make sure the React app points to `http://localhost:3001` or wherever your backend is running.
 
    In my frontend/.env i have :
    `REACT_APP_BACKEND_URL=http://localhost:3000`

5. **Run Services Locally Without Docker**
    
- Go to the backend/ folder with `cd backend`

  Run the command below: To install dependencies and start the backend
      
    ```bash
     npm install
    
     npm start
     ```
      
    ![image3](./img/img3.png)
     *img2: Shows backend Connected to local PostgreSQL and Server is running on port 3001*

- Open a new terminal and go to frontend/ with `cd frontend`

  Run the command:To install dependencies and start the frontend

    ```bash
       npm install
       npm start
    ```
    ![imge3](./img/img4.png)
    *img3:The screenshot shows frontend is     successfully connected*
    
 5. **Test the App**
- Go to `http://localhost:3000`  to check the frontend.
- Go to `http://localhost:3001/api/destinations` to check the backend.

   ![image4](./img/img5.png)
   *img4:This confirms frontend reaches backend*
 

### Step 2: Containerize the Dream Vacation App using Docker and Docker Compose.

1. **Write a Dockerfile for both the frontend and backend.**

- Go to frontend/ to create and write a Dockerfile (Multi-Stage + Nginx) for the forntend.

    - Go to frontend with `cd frontent/` command.
    - Create and write the Dockerfile with `nano Dockerfile` command.

    ![image5](./img/Dockerfile-f.png)
    *img5: The frontend Dockerfile*

-  Go to backend/ to create and write a Dockerfile for the backend.

    - Go to backend with `cd backend/` command.
    - Create and write the Dockerfile with `nano Dockerfile` command.  

    ![image6](./img/Dockerfile-b.png)
    *img6: The backend Dockerfile*  

2. **Update backend .env file with:**
    
    backend/.env
   `DATABASE_URL=postgresql://db_user:password@db:5432/db_name`    


3. **Create the folloing directories and file to help Ignore  sensitive files and reduce image size.**

- `.env.example`: Safe sample env file (COMMIT)
- `.gitignore`  : Ignore build files, env & Node backend code
- `.dockerignore` :Reduce Docker image size

 
4. **Build and Push Docker Images**

- Go to the terminal to login to your dockerhub.
    - Login with `docker login` you will be prompted for your password.

- Go to Backend with `cd backend`

    - Build and push the backend image to dockerhub.
```bash
# command to build image    
docker build -t yourdockerhub/dream-backend:latest .

# command to push image
docker push yourdockerhub/dream-backend:latest
```

![image7](./img/img6.png)
*img7:Shows build the backend image*
![image8](./img/img7.png)
*img8:Shows pushing backend to dockerhub*
- Go to Backend with `cd frontend`

  - Build and push the frontend image to dockerhub.

```bash
#command to build image
docker build -t yourdockerhub/dream-frontend:latest .

#command to push image
docker push yourdockerhub/dream-frontend:latest
```
![image9](./img/img8.png)
*img9:Shows build the frontend image*
![image10](./img/img9.png)
*img10:Shows pushing frontend to dockerhub*

5. **Create a `docker-compose.yml`**

  - Go to the root directory to create a `docker-compose.yml` file.

  ```bash

networks:
  dream-network:
    driver: bridge

volumes:
  pgdata:

services:
  db:
    image: postgres:15
    container_name: pg-db
    env_file:
      - ./backend/.env
    environment:
      POSTGRES_DB: ${DB_NAME}
      POSTGRES_USER: ${DB_USER}
      POSTGRES_PASSWORD: ${DB_PASSWORD}
    volumes:
      - pgdata:/var/lib/postgresql/data
    ports:
      - "5432:5432"
    networks:
      - dream-network

  backend:
    image: wilfred2018/dream-backend:kc-v1
    container_name: backend
    env_file:
      - ./backend/.env
    depends_on:
      - db
    ports:
      - "3001:3001"
    networks:
      - dream-network

  frontend:
    image: wilfred2018/dream-frontend:kc-v1
    container_name: frontend
    env_file:
      - ./frontend/.env
    depends_on:
      - backend
    ports:
      - "80:80"
    networks:
      - dream-network
```

![imgae11](./img/docker-compose-yml.png)
*img11:Shows the content of my docker compose file*


6. **Pull image and Start containers**

- Use the commands below to pull image and start the containers

```bash
# Pull images
docker-compose pull

# Start containers
docker-compose up -d
```
![image12](./img/img10.png)
*img12:Pulling the Images*

![image13](./img/img11.png)
*img13:Shows Starting the containers*

- Confirm containers are runing with `docker ps`

![image14](./img/docker-ps.png)
*img14:Shows containers is runing*

7. **Access the App**

- Test using the browser

    Frontend : http://localhost/80

    Backend : http://localhost:3001/api/destinations

![image15](./img/img12.png)
*img14:Showing frontend and backend*    






    







  




