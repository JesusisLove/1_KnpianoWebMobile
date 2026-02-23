package com.liu.springboot04web.config;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.web.servlet.config.annotation.CorsRegistry;
import org.springframework.web.servlet.config.annotation.WebMvcConfigurer;

/**
 * 2025-02-23
 * 解释一下配置类中的关键部分：
 * @Configuration：告诉Spring这是一个配置类
 * @Value("${cors.allowed-origin}")：从配置文件中读取allowed-origin的值
 * @Bean：将这个配置注册为Spring Bean
 * addMapping("/**")：将CORS配置应用到所有URL路径
 * allowedOrigins(allowedOrigin)：设置允许跨域请求的源
 * allowedMethods()：设置允许的HTTP方法
 * allowedHeaders()：设置允许的请求头
 * allowCredentials()：是否允许发送Cookie
 * maxAge()：预检请求的有效期
 * 
 * 使用这个配置后，你的Controller就不需要添加@CrossOrigin注解了：
 */

@Configuration  // 标记这是一个配置类
public class CorsConfig {
    @Value("${cors.allowed-origin}")  // 注入application.yml配置文件中的值
    private String allowedOrigin; // 这个值是在yaml文件里配置的值（http://10.8.0.6:8080），指定具体的访问源
    
    @Bean  // 创建一个Spring Bean
    public WebMvcConfigurer corsConfigurer() {
        return new WebMvcConfigurer() {
            @Override
            public void addCorsMappings(CorsRegistry registry) {
                registry.addMapping("/**")  // 对所有接口路径应用CORS配置
                        // 允许配置的源以及本地开发环境，解决flutter前端设备启动的是chrome或者msios的时候页面数据不加载的问题。
                        // 添加局域网IP支持，允许通过局域网内其他设备（如手机浏览器）访问Flutter Web应用并调用API
                        .allowedOriginPatterns(allowedOrigin, "http://localhost:*", "http://127.0.0.1:*", "http://0.0.0.0:*", "http://192.168.*:*")
                        .allowedMethods("GET", "POST", "PUT", "DELETE")  // 允许的HTTP方法
                        .allowedHeaders("*")  // 允许的请求头
                        .allowCredentials(true)  // 允许发送cookie
                        .maxAge(3600);  // 预检请求的有效期，单位为秒
            }
        };
    }
}