package core

import (
	"fmt"
	"strings"

	"github.com/go-playground/validator/v10"
)

var validate = validator.New()

// ValidateStruct validates a struct based on its `validate` tags
func ValidateStruct(s interface{}) error {
	err := validate.Struct(s)
	if err != nil {
		if _, ok := err.(*validator.InvalidValidationError); ok {
			return err
		}

		errMsgs := []string{}
		for _, err := range err.(validator.ValidationErrors) {
			errMsgs = append(errMsgs, fmt.Sprintf("%s is %s", err.Field(), err.Tag()))
		}
		return fmt.Errorf("validation failed: %s", strings.Join(errMsgs, ", "))
	}
	return nil
}
