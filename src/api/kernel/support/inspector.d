/**
 * Authors: initkfs
 */
module api.kernel.support.inspector;

private __gshared
{
    //TODO messages
	bool errors;
}

bool isErrors()
{
	return errors;
}

void setErrors()
{
	errors = true;
}
